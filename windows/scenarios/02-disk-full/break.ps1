<#
.SYNOPSIS
    Scenario 02 - fill drive C: on WS01 with one large file until about 5% is free.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\LabSafety.ps1"

$fillDir = 'C:\ProgramData\LabApp'
$fillFile = Join-Path $fillDir 'cache.dat'

Assert-LabHost -Allowed 'WS01'
Assert-Administrator

if (Test-Path $fillFile) { throw "$fillFile already exists. Run restore.ps1 first." }

$disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID = 'C:'"

# Always leave some space so Windows keeps working: 5% of the disk, but never less than 2 GB.
$keepBytes = [math]::Max([long]($disk.Size * 0.05), 2GB)
$fillBytes = [long]($disk.FreeSpace - $keepBytes)
if ($fillBytes -le 0) { throw 'C: already has very little free space. Nothing to do.' }

Confirm-LabAction "This will create a $([math]::Round($fillBytes / 1GB, 1)) GB file at $fillFile."

if (-not (Test-Path $fillDir)) { New-Item -Path $fillDir -ItemType Directory | Out-Null }
# fsutil reserves the space at once without writing data, so it is fast.
fsutil file createnew $fillFile $fillBytes | Out-Null

Write-Output "Fault injected. Ticket: 'Users report that $env:COMPUTERNAME is slow and says the disk is almost full.'"
Write-Output 'When you are done, run: .\restore.ps1'
