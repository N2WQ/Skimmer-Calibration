The script is using the latest version of PowerShell on a fully patched Windows 11 computer. I have not tested on anything else and some volunteers indicated that older versions don't quite work.
No ham piece of software ever runs as Admin on any of my computers. This is the reason I am using some of the extra options to kill and launch processes.
I have updated the script to skip updating the INI files if Skew=0. I noticed that Bjorn's script produces a correction factor of greater than 1.0 even though Skew=0 (I understand why).
The script generates a detailed log in the USER root directory.
The script does not run on its own; it is scheduled via Windows Task Scheduler to run at whatever time, on whatever schedule. It is your choice. If the SDR runs in temperature stable environment, the script doesn't need to run often. In my case, shack temp swings quite a lot and the script runs daily at 00:30 UTC.
CWSL Digi also requires calibration, but the new calibration is the reciprocal of the value for CW and RTTY. I am toying with the idea of modifying the script to have an optional parameter that return a calibration for CWSL Digi...but this will have to wait a little bit.
Separately, I was wondering how would node operators know that they should calibrate their SDRs and how to do it? The RBN site has nothing on the subject and the only info I have found is here and on Bjorn's site. Perhaps the RBN site should include something on the subject.
 
If you are using the script, I'd love to hear from you how it's working and if any tweaks are needed.
