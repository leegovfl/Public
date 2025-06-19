param (
    [switch]$P,
    [switch]$F
)
$hottogo = $false

if (Test-Path -Path "$($env:ProgramData)\LeeCounty\PreProvision\PreProvision.tag") {    
    $title    = 'Re-run Script'
    $question = 'This script has already been ran on this device, do you want to re-run it?'
    $choices  = '&Yes', '&No', '&Repeat the Question'
    do {
        $decisionS = $Host.UI.PromptForChoice($title, $question, $choices, 2)
    } while ($decisionS -ne 0 -and $decisionS -ne 1)
    if ($decisionS -eq 0) {
        $hottogo = $true;
    }
} else {
   $hottogo = $true
}

if($hottogo){
    $build = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion") | Select-Object -Property DisplayVersion,CurrentBuildNumber,UBR,EditionID,ProductName
    write-host "Current Windows Version: $($build.EditionID) $($build.DisplayVersion) $($build.CurrentBuildNumber).$($build.UBR)" -ForegroundColor Cyan
    #min required: 22H2 22621.3374 or 23H2 22631.3374 or 24H2
    if($build.EditionID -eq "Enterprise") {
    if (($build.CurrentBuildNumber -eq 22621 -and $build.UBR -ge 3374) -or ($build.CurrentBuildNumber -eq 22631 -and $build.UBR -ge 3374) -or $build.CurrentBuildNumber -ge 26100)
    {
        $spTenant = "leegovfl.sharepoint.com"
        $spSitePath = "/sites/ProvConn"
        $spLibrary = "APV2"
        $outputFolder = "c:\ITS"
        
        if(-not $F)
        {
            write-host "Installing libraries..." -ForegroundColor Magenta
            #Set-ExecutionPolicy Unrestricted
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
            Install-Module msal.ps -Force
            Import-Module msal.ps
            Install-Module Microsoft.Graph -Force
            #Import-Module Microsoft.Graph
            #Install-Module Microsoft.Graph.Files -Force
            Import-Module Microsoft.Graph.Files
        }
        $decision = 0
        $title    = 'Download Files'
        $question = 'Do you want to start downloading files on this computer?'
        if(-not $F)
        {
            $title    = 'Pre-Provision Computer'
            $question = 'Do you want to start the pre-provisioning process on this computer?'
        }
        if(-not $P)
        {

            $choices  = '&Yes', '&No', '&Repeat the Question'
            do {
                $decision = $Host.UI.PromptForChoice($title, $question, $choices, 2)
            } while ($decision -ne 0 -and $decision -ne 1)
        }
        if ($decision -eq 0 -or $P) {
            Write-Host "Set Timezone" -ForegroundColor Yellow
            Set-TimeZone -Id "Eastern Standard Time"
            Connect-MgGraph -Scopes "Device.ReadWrite.All,DeviceManagementManagedDevices.ReadWrite.All,DeviceManagementServiceConfig.ReadWrite.All,Sites.ReadWrite.All,User.Read.All,Sites.Read.All,Sites.Selected"
             write-host "Downloading ITS files..." -ForegroundColor Magenta
            # Create the folder
            if (-not (Test-Path $outputFolder))
            {
                New-Item -Path $outputFolder -ItemType Directory
            }
            
            # Set permissions to allow only Administrators full access
            $acl = Get-Acl $outputFolder
            $acl.SetAccessRuleProtection($true, $false)
            
            # Remove inherited permissions
            $acl.SetAccessRuleProtection($true, $false)
            
            # Add full control for Administrators
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "Allow")
            $acl.AddAccessRule($rule)
            
            # Set the ACL on the folder
            Set-Acl $outputFolder $acl
            
            
            $sps = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/sites/$($spTenant):/$($spSitePath)"
            $spds = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/sites/$($sps.id)/drives?$filter=name eq '$($spLibrary)'"
            $driveId = ""
            
            foreach ($spd in $spds.value)
            {
                if($spd.name -eq $spLibrary) {
                    $driveId = $spd.id
                }
            }
            function getFiles {
              param(
                [string]$folderId,
                [string]$folderPath
              )
            
                    $spfileurl = "https://graph.microsoft.com/v1.0/drives/$($driveId)/root/children"
            
                    if($folderId -ne ""){
                        $spfileurl = "https://graph.microsoft.com/v1.0/drives/$($driveId)/items/$($folderId)/children"
                    }
                        
                    [array]$dis = Invoke-MgGraphRequest -Method GET -Uri $spfileurl
        
                    $Folders = $dis.Value | ? {$_.Folder.ChildCount -gt 0 }
                    $Files = $dis.Value | ? {$_.Folder.ChildCount -eq $Null}
                    #$Files
                    foreach ($di in $Files)
                    {        
                        Get-MgDriveItemContent -DriveId $driveId -DriveItemId $di.id -OutFile "$($outputFolder)\$($folderPath)$($di.name)"
                    }
                    foreach ($di in $Folders)
                    {
                        $nfolderPath = $folderPath + $di.name  + "\"
                        getFiles -folderId $di.id -folderPath $nfolderPath
                    }
                    
              
             }
            if($driveId -ne ""){            
                getFiles
            }
            
            #copy drivemappings file
            $dest = "$($env:ProgramData)\LeeCounty\DriveMapping"
            if (-not (Test-Path $dest))
            {
                mkdir $dest
            }
            Copy-Item "$($outputFolder)\DriveMappings.ps1" -Destination $dest -Force  
        
            #$dest = "$($env:ProgramData)\LeeCounty\renamePC"
            #if (-not (Test-Path $dest))
            #{
            #    mkdir $dest
            #}
            #Copy-Item "$($outputFolder)\Post-APV2-Reboot.ps1" -Destination $dest -Force  
            #Copy-Item "$($outputFolder)\Post-APV2-Reboot-Notification.ps1" -Destination $dest -Force  
            #copy oobe.xml
            #$dest = "$($env:windir)\System32\Oobe\Info"
            #if (-not (Test-Path $dest))
            #{
            #    mkdir $dest
            #}
            #Copy-Item "$($outputFolder)\oobe.xml" -Destination $dest -Force  
            if(-not $F)
            {
                #provision computer
                powershell.exe -executionpolicy bypass -file "$($outputFolder)\DellCommandConfigure.ps1"
                powershell.exe -executionpolicy bypass -file "$($outputFolder)\registerDevice.ps1" -P
                powershell.exe -executionpolicy bypass -file "$($outputFolder)\pro2ent.ps1"
                powershell.exe -executionpolicy bypass -file "$($outputFolder)\add2apv2.ps1"
                powershell.exe -executionpolicy bypass -file "$($outputFolder)\absolute.ps1"
                powershell.exe -executionpolicy bypass -file "$($outputFolder)\drivemappingscheduler.ps1"            
                powershell.exe -executionpolicy bypass -file "$($outputFolder)\addBackgrounds.ps1"
                powershell.exe -executionpolicy bypass -file "$($outputFolder)\pdqconnect.ps1"
                powershell.exe -executionpolicy bypass -file "$($outputFolder)\settings.ps1"
                #powershell.exe -executionpolicy bypass -file "$($outputFolder)\renamePC.ps1"
    
                #write installed tag
                # Create a tag file just so Intune knows this was installed
                if (-not (Test-Path "$($env:ProgramData)\LeeCounty\PreProvision"))
                {
                    Mkdir "$($env:ProgramData)\LeeCounty\PreProvision"
                }
                Set-Content -Path "$($env:ProgramData)\LeeCounty\PreProvision\PreProvision.tag" -Value "Installed"
                
                Write-Host "*******************************************************************************************" -ForegroundColor Cyan
                Write-Host "* Pre-Provisioning Complete. Close this window to continue provisioning this device." -ForegroundColor Cyan
                Write-Host "*******************************************************************************************" -ForegroundColor Cyan
    
                #exit 1641
                #$title    = 'Restart Computer'
                #$question = 'Do you want to restart this computer now (recommended)?'
                #$title    = 'Provision Computer'
                #$question = 'Do you want to continue provisioning this computer?'
                #$choices  = '&Yes', '&No', '&Repeat the Question'
                #do {
                #    $decisionR = $Host.UI.PromptForChoice($title, $question, $choices, 2)
                #} while ($decisionR -ne 0 -and $decisionR -ne 1)
                #if ($decisionR -eq 0) {    
                    #powershell.exe -executionpolicy bypass -file "$($outputFolder)\sysprep.ps1"
                    #shutdown /g /f /t 0
                    #exit 1641
                    #exit
                #}
            }
        }
    
    }else {
    
        write-host "This version of Windows is not compatible with Autopilot V2. Please update to at least Windows 11 22H2 22621.3374 or 23H2 22631.3374 or 24H2"
        $title    = 'Update Windows'
        $question = 'Do you want to run Winndows Update?'
        $choices  = '&Yes', '&No', '&Repeat the Question'
        do {
            $decisionW = $Host.UI.PromptForChoice($title, $question, $choices, 2)
        } while ($decisionW -ne 0 -and $decisionW -ne 1)
        if ($decisionW -eq 0) {    
            Install-Module -Name PSWindowsUpdate -Force
            Import-Module -Name PSWindowsUpdate
            Get-WindowsUpdate -AcceptAll -Install -AutoReboot
        }

        
    }
    }else {
         write-host "Windows Enterprise is required for Autopilot V2"
        $title    = 'Upgrade Windows to Enterprise'
        $question = 'Do you want to run Winndows Upgrade?'
        $choices  = '&Yes', '&No', '&Repeat the Question'
        do {
            $decisionW = $Host.UI.PromptForChoice($title, $question, $choices, 2)
        } while ($decisionW -ne 0 -and $decisionW -ne 1)
        if ($decisionW -eq 0) {    
            $sls = Get-WmiObject -Query 'SELECT * FROM SoftwareLicensingService' 
            @($sls).foreach({
                $_.InstallProductKey('NPPR9-FWDCX-D2C8J-H872K-2YT43')
                $_.RefreshLicenseStatus()
            })
            systemreset
        }
        
    }
}
