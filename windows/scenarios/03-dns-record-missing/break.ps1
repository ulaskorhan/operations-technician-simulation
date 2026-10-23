<#
.SYNOPSIS
    Scenario 03 - delete the A record "intranet" from the lab.local zone on DC01.

.DESCRIPTION
    The record must exist first. If it does not, run restore.ps1 once to create the baseline record.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\LabSafety.ps1"

$zone = 'lab.local'
$recordName = 'intranet'
$stateFile = Join-Path $script:LabStateDir '03-dns-record.txt'

Assert-LabHost -Allowed 'DC01'
Assert-Administrator

if (Test-Path $stateFile) { throw 'Saved state already exists, so the fault is probably active. Run restore.ps1 first.' }

$record = Get-DnsServerResourceRecord -ZoneName $zone -Name $recordName -RRType A -ErrorAction SilentlyContinue
if (-not $record) { throw "Record $recordName.$zone does not exist. Run restore.ps1 once to create the baseline." }

Confirm-LabAction "This will DELETE the DNS record $recordName.$zone ($($record.RecordData.IPv4Address))."

Initialize-LabStateDir
# Save the IP address so restore.ps1 can create the same record again.
$record.RecordData.IPv4Address.IPAddressToString | Set-Content -Path $stateFile

Remove-DnsServerResourceRecord -ZoneName $zone -Name $recordName -RRType A -Force

Write-Output "Fault injected. Ticket: 'Users cannot open http://$recordName.$zone - the page cannot be found.'"
Write-Output 'When you are done, run: .\restore.ps1'
