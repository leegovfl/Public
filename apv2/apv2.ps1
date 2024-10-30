﻿$spTenant = "leegovfl.sharepoint.com"
$spSitePath = "/sites/InformationTechnology"
$spLibrary = "apv2"
$outputFolder = "c:\ITS"

Install-Module Microsoft.Graph
Import-Module Microsoft.Graph

Connect-MgGraph

Install-Module Microsoft.Graph.Files
Import-Module Microsoft.Graph.Files

$sps = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/sites/$($spTenant):/$($spSitePath)"

$spds = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/sites/$($sps.id)/drives?$filter=name eq 'apv2'"

$driveId = ""

foreach ($spd in $spds.value)
{
    if($spd.name -eq $spLibrary) {
        $driveId = $spd.id
    }
}
$driveId

#create dir with permissons?

if($driveId -ne ""){

    $dis = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/drives/$($driveid)/root/children"

    foreach ($di in $dis.value)
    {
        Get-MgDriveItemContent -DriveId $driveId -DriveItemId $di.id -OutFile "$($outputFolder)\$($di.name)"
    }


}

powershell.exe -executionpolicy bypass -file "$($outputFolder)\pro2ent.ps1"
powershell.exe -executionpolicy bypass -file "$($outputFolder)\add2apv2.ps1"
powershell.exe -executionpolicy bypass -file "$($outputFolder)\renamePC.ps1"


$title    = 'Restart Computer'
$question = 'Do you want to restart computer now?'
$choices  = '&Yes', '&No'

$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
if ($decision -eq 0) {
    shutdown -r -f -t 00
}
