<#
.SYNOPSIS
    Scenario 01 - stop the Print Spooler service on WS01 and set it to Disabled.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\LabSafety.ps1"

$serviceName = 'Spooler'
$stateFile = Join-Path $script:LabStateDir '01-spooler-starttype.txt'

Assert-LabHost -Allowed 'WS01'
Assert-Administrator

if (Test-Path $stateFile) { throw 'Saved state already exists, so the fault is probably active. Run restore.ps1 first.' }

Confirm-LabAction "This will STOP the $serviceName service on $env:COMPUTERNAME and set it to Disabled."

Initialize-LabStateDir
# Save the current startup type (for example "Automatic") so restore.ps1 can put it back.
(Get-Service -Name $serviceName).StartType.ToString() | Set-Content -Path $stateFile

Stop-Service -Name $serviceName -Force
Set-Service -Name $serviceName -StartupType Disabled

Write-Output "Fault injected. Ticket: 'A user on $env:COMPUTERNAME cannot print, and the printers have disappeared.'"
Write-Output 'When you are done, run: .\restore.ps1'
