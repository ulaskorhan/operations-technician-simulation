<#
.SYNOPSIS
    Scenario 01 - restore the Print Spooler startup type and start it.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\LabSafety.ps1"

$serviceName = 'Spooler'
$stateFile = Join-Path $script:LabStateDir '01-spooler-starttype.txt'

Assert-LabHost -Allowed 'WS01'
Assert-Administrator

# Use the saved startup type, or the Windows default (Automatic) if nothing was saved.
$startType = 'Automatic'
if (Test-Path $stateFile) {
    $startType = (Get-Content -Path $stateFile).Trim()
    Remove-Item -Path $stateFile
}

Set-Service -Name $serviceName -StartupType $startType
Start-Service -Name $serviceName

Get-Service -Name $serviceName | Select-Object -Property Name, Status, StartType
