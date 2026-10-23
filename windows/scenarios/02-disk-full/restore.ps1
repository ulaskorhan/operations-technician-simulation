<#
.SYNOPSIS
    Scenario 02 - remove the large file and its folder.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\LabSafety.ps1"

$fillDir = 'C:\ProgramData\LabApp'
$fillFile = Join-Path $fillDir 'cache.dat'

Assert-LabHost -Allowed 'WS01'
Assert-Administrator

if (Test-Path $fillFile) { Remove-Item -Path $fillFile -Force }

# Only remove the folder if it is empty, so nothing else is deleted by mistake.
if ((Test-Path $fillDir) -and -not (Get-ChildItem -Path $fillDir -Force)) {
    Remove-Item -Path $fillDir
}

Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID = 'C:'" |
    Select-Object -Property DeviceID, @{ Name = 'FreeGB'; Expression = { [math]::Round($_.FreeSpace / 1GB, 1) } }
