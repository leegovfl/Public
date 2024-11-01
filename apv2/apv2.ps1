$spTenant = "leegovfl.sharepoint.com"
$spSitePath = "/sites/InformationTechnology"
$spLibrary = "apv2"
$outputFolder = "c:\ITS"

#Install-Module Microsoft.Graph
#Import-Module Microsoft.Graph

Install-Module Microsoft.Graph.Files -Force
Import-Module Microsoft.Graph.Files

Connect-MgGraph

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
$title    = 'Pre-Provision Computer'
$question = 'Do you want to start the pre-provisioning process on this computer?'
$choices  = '&Yes', '&No'
$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
if ($decision -eq 0) {

    powershell.exe -executionpolicy bypass -file "$($outputFolder)\pro2ent.ps1"
    powershell.exe -executionpolicy bypass -file "$($outputFolder)\add2apv2.ps1"
    powershell.exe -executionpolicy bypass -file "$($outputFolder)\addBackgrounds.ps1"
    powershell.exe -executionpolicy bypass -file "$($outputFolder)\renamePC.ps1"
    
    
    $title    = 'Restart Computer'
    $question = 'Do you want to restart this computer now?'
    $choices  = '&Yes', '&No'
    
    $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
    if ($decision -eq 0) {
        shutdown -r -f -t 00
    }
}
