param (
    [switch]$P
)
 
$spTenant = "leegovfl.sharepoint.com"
$spSitePath = "/sites/InformationTechnology"
$spLibrary = "apv2"
$outputFolder = "c:\ITS"

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module Microsoft.Graph -Force
#Import-Module Microsoft.Graph
#Install-Module Microsoft.Graph.Files -Force
Import-Module Microsoft.Graph.Files

Connect-MgGraph

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
$spds = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/sites/$($sps.id)/drives?$filter=name eq 'apv2'"
$driveId = ""

foreach ($spd in $spds.value)
{
    if($spd.name -eq $spLibrary) {
        $driveId = $spd.id
    }
}

if($driveId -ne ""){

    $dis = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/drives/$($driveid)/root/children"

    foreach ($di in $dis.value)
    {
        Get-MgDriveItemContent -DriveId $driveId -DriveItemId $di.id -OutFile "$($outputFolder)\$($di.name)"
    }


}
#copy drivemappings file
$dest = "$($env:ProgramData)\LeeCounty\DriveMapping"
if (-not (Test-Path $dest))
{
    mkdir $dest
}
Copy-Item "$($outputFolder)\DriveMappings.ps1" -Destination $dest -Force  
    
$decision = 0
if(-not $P)
{
    $title    = 'Pre-Provision Computer'
    $question = 'Do you want to start the provisioning process on this computer?'
    $choices  = '&Yes', '&No'
    $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
}
if ($decision -eq 0 -or $P) {
    #provision computer
    powershell.exe -executionpolicy bypass -file "$($outputFolder)\registerDevice.ps1"
    powershell.exe -executionpolicy bypass -file "$($outputFolder)\pro2ent.ps1"
    powershell.exe -executionpolicy bypass -file "$($outputFolder)\add2apv2.ps1"
    powershell.exe -executionpolicy bypass -file "$($outputFolder)\drivemappingscheduler.ps1"    
    powershell.exe -executionpolicy bypass -file "$($outputFolder)\addBackgrounds.ps1"
    powershell.exe -executionpolicy bypass -file "$($outputFolder)\sysprep.ps1"        
    
    #Disable-LocalUser -Name "Administrator"

}
