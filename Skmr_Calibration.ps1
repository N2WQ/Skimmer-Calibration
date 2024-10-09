function Update-FreqCalibration {
    param (
        [string]$INI_Location,     # Path to the INI file
        [string]$Calibration_URL   # URL pointing to the CSV file
    )

    # Create a log file with the execution date as the filename
    $logFileName = "$(Get-Date -Format 'yyyy-MM-dd')_FreqCalibration_Log.txt"
    $logFilePath = Join-Path -Path $env:USERPROFILE -ChildPath $logFileName

    # Function to log messages to both console and log file
    function Write-Log {
        param (
            [string]$message
        )
        # Write the message to the console
        Write-Host $message
        # Write the message to the log file
        $message | Out-File -FilePath $logFilePath -Append
    }

    # Initialize the variable for Skmr_Call (extracted from the INI file)
    $Skmr_Call = ""

    # Step 1: Open the INI file and search for the line that starts with 'Call='
    Write-Log "Reading INI file from: $INI_Location"
    
    try {
        # Read the INI file into an array where each element is a line from the file
        $ini_content = Get-Content -Path $INI_Location
        Write-Log "INI file read successfully."
    } catch {
        Write-Log "Error: Failed to read INI file."
        return
    }

    # Loop through each line in the INI file to find the line that starts with 'Call='
    foreach ($line in $ini_content) {
        if ($line -like "Call=*") {
            # Extract the value after the '=' sign and trim any whitespace
            $Skmr_Call = $line.Split('=')[1].Trim()
            Write-Log "Skmr_Call extracted: $Skmr_Call"
            break  # Exit the loop once the Call= line has been found
        }
    }

    # Step 2: Download and read the CSV file from the provided URL
    Write-Log "Downloading CSV from: $Calibration_URL"
    
    try {
        # Use Invoke-WebRequest to retrieve the CSV file and convert it into a PowerShell object
        $csv_data = Invoke-WebRequest -Uri $Calibration_URL | ConvertFrom-Csv
        Write-Log "CSV downloaded and converted successfully."
    } catch {
        Write-Log "Error: Failed to download or parse CSV file."
        return
    }

    # Step 3: Read the 'FreqCalibration=' line from the INI file and update the value based on the correction factor
    Write-Log "Looking for FreqCalibration line in INI file"
    
    # Loop through the INI content again to find the 'FreqCalibration=' line
    for ($i = 0; $i -lt $ini_content.Count; $i++) {
        if ($ini_content[$i] -like "FreqCalibration=*") {
            try {
                # Extract and convert the current FreqCalibration value to a double
                $current_value = [double]($ini_content[$i].Split('=')[1].Trim())
                Write-Log "Current FreqCalibration value: $current_value"

                # Find the corresponding row in the CSV where the Callsign matches $Skmr_Call
                $calibration_row = $csv_data | Where-Object { $_.Callsign -eq $Skmr_Call }

                # Check if a matching row was found in the CSV
                if ($calibration_row) {
                    # Check if Skew is 0.0, and if so, log and exit without updating
                    $skew_value = [double]$calibration_row.Skew
                    if ($skew_value -eq 0.0) {
                        Write-Log "Skew value is 0.0 for Skmr_Call: $Skmr_Call. Exiting without updating INI file."
                        return
                    }

                    # Extract the Correction factor from the matching row and convert it to a double
                    $correction_factor = [double]$calibration_row."Correction factor"
                    Write-Log "Correction factor from CSV: $correction_factor"

                    # Calculate the new FreqCalibration value by multiplying the current value by the correction factor
                    $new_value = $current_value * $correction_factor
                    Write-Log "New FreqCalibration value: $new_value"

                    # Update the 'FreqCalibration=' line in the INI content with the new value
                    $ini_content[$i] = "FreqCalibration=$new_value"
                    Write-Log "FreqCalibration value updated in INI file."
                } else {
                    Write-Log "Error: No matching call sign found in CSV for Skmr_Call: $Skmr_Call"
                }

            } catch {
                Write-Log "Error: Failed to update FreqCalibration value."
            }

            break  # Exit the loop once the FreqCalibration= line has been processed
        }
    }

    # Step 4: Save the updated INI file back to the original location
    Write-Log "Saving updated INI file to: $INI_Location"
    
    try {
        # Write the updated INI content back to the file
        $ini_content | Set-Content -Path $INI_Location
        Write-Log "INI file saved successfully."
    } catch {
        Write-Log "Error: Failed to save INI file."
    }

    Write-Log "Function execution complete."
}

# Example usage:
# Update-FreqCalibration -INI_Location "C:\path\to\your\ini_file.ini" -Calibration_URL "https://your_csv_url.csv"

# Stop all skimmer related processes
$processNames = @("RX1-RTTY-SkimServ.exe", "RX2-RTTY-SkimServ.exe", "RX1-CW-SkimSrv.exe", "RX2-CW-SkimSrv.exe", "Aggregator.exe", "cwreporter.exe", "jt9.exe", "wsprd.exe", "js8call.exe", "RX1-CWSL_DIGI.exe")
foreach ($processName in $processNames) {
    Start-Process -FilePath "taskkill" -ArgumentList "/IM $processName /F /T" -NoNewWindow -Wait -ErrorAction SilentlyContinue
}

# Update INI files
Update-FreqCalibration -INI_Location "C:\Users\Skimmer Server\AppData\Roaming\Afreet\Products\RX1-CW-SkimSrv\RX1-CW-SkimSrv.ini" -Calibration_URL "https://sm7iun.se/rbnskew.csv"
Update-FreqCalibration -INI_Location "C:\Users\Skimmer Server\AppData\Roaming\Afreet\Products\RX1-RTTY-SkimServ\RX1-RTTY-SkimServ.ini" -Calibration_URL "https://sm7iun.se/rbnskew.csv"
Update-FreqCalibration -INI_Location "C:\Users\Skimmer Server\AppData\Roaming\Afreet\Products\RX2-CW-SkimSrv\RX2-CW-SkimSrv.ini" -Calibration_URL "https://sm7iun.se/rbnskew.csv"
Update-FreqCalibration -INI_Location "C:\Users\Skimmer Server\AppData\Roaming\Afreet\Products\RX2-RTTY-SkimServ\RX2-RTTY-SkimServ.ini" -Calibration_URL "https://sm7iun.se/rbnskew.csv"

# Relaunch Aggregator
Write-Log "Setting working directory to: D:\Aggregator\"
Set-Location "D:\Aggregator\"

# Log the start of Aggregator
Write-Log "Launching Aggregator.exe from D:\Aggregator\"

try {
    # Use Start-Process with -PassThru to capture process information and check if it starts correctly
    $process = Start-Process "D:\Aggregator\Aggregator.exe" -PassThru -NoNewWindow -ErrorAction Stop
    Write-Log "Aggregator launched successfully with Process ID: $($process.Id)"
} catch {
    Write-Log "Error: Failed to launch Aggregator.exe. Exception: $_"
}





