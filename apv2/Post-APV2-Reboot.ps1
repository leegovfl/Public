﻿$dest = "$($env:ProgramData)\LeeCounty\renamePC"
if (-not (Test-Path $dest))
{
    mkdir $dest
}
Start-Transcript "$dest\Post-APV2-Reboot.log" #-Append


Start-ScheduledTask -TaskName "Post-APV2-Reboot-Notification"
Start-Sleep -Seconds 21

disable-scheduledtask -taskname Post-APV2-Reboot -ErrorAction SilentlyContinue -Verbose
#Unregister-ScheduledTask -TaskName Post-APV2-Reboot -Confirm:$false
disable-scheduledtask -taskname Post-APV2-Reboot-Notification -Erroraction Continue -Verbose
#Unregister-ScheduledTask -TaskName Post-APV2-Reboot-Notification -Confirm:$false


Restart-Computer -Force -Verbose


Stop-transcript
