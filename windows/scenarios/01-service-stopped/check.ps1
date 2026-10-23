<#
.SYNOPSIS
    Scenario 01 - check (read-only): is the Print Spooler running and set to start automatically?
#>
[CmdletBinding()]
param()

$service = Get-Service -Name 'Spooler'

if ($service.Status -eq 'Running') { Write-Output '[ OK ] Spooler is running' }
else { Write-Output "[FAIL] Spooler is $($service.Status)" }

if ($service.StartType -eq 'Automatic') { Write-Output '[ OK ] Spooler starts automatically' }
else { Write-Output "[FAIL] Spooler start type is $($service.StartType)" }

# Event ID 7036 = "service entered the running/stopped state"; 7040 = "start type was changed".
Write-Output 'Recent Service Control Manager events for the spooler:'
Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Service Control Manager'; Id = 7036, 7040 } -MaxEvents 50 -ErrorAction SilentlyContinue |
    Where-Object { $_.Message -match 'Print Spooler' } |
    Select-Object -First 5 -Property TimeCreated, Id, Message |
    Format-Table -AutoSize -Wrap
