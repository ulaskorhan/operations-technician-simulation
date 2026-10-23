<#
.SYNOPSIS
    Scenario 02 - check (read-only): does C: have at least 10% free?
#>
[CmdletBinding()]
param([int]$WarnPercent = 10)

$disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID = 'C:'"
$freePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 1)
$freeGB = [math]::Round($disk.FreeSpace / 1GB, 1)

if ($freePercent -ge $WarnPercent) { Write-Output "[ OK ] C: has $freeGB GB free ($freePercent%)" }
else { Write-Output "[FAIL] C: has only $freeGB GB free ($freePercent%), threshold $WarnPercent%" }
