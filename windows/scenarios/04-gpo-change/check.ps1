<#
.SYNOPSIS
    Scenario 04 - check (read-only) on WS01: is the logon banner policy applied?
#>
[CmdletBinding()]
param()

# Group Policy writes the banner settings to this registry key.
$key = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
$values = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue

if ($values.legalnoticecaption) { Write-Output "[INFO] Banner title: $($values.legalnoticecaption)" }
else { Write-Output '[INFO] Banner title: (not set)' }

if ($values.legalnoticetext) { Write-Output "[INFO] Banner text:  $($values.legalnoticetext)" }
else { Write-Output '[INFO] Banner text:  (not set)' }

# When did computer Group Policy last finish? 8000 = at boot, 8004 = periodic refresh, 8006 = manual (gpupdate).
$last = Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-GroupPolicy/Operational'; Id = 8000, 8004, 8006 } -MaxEvents 1 -ErrorAction SilentlyContinue
if ($last) { Write-Output "[INFO] Last Group Policy processing: $($last.TimeCreated)" }
