<#
.SYNOPSIS
    Scenario 03 - create the A record "intranet" in lab.local (also used once to create the baseline).
#>
[CmdletBinding()]
param(
    # Default target: OPS-LNX02, which runs nginx. TODO: change 192.168.100 to your lab subnet.
    [string]$DefaultIPv4 = '192.168.100.41'
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\LabSafety.ps1"

$zone = 'lab.local'
$recordName = 'intranet'
$stateFile = Join-Path $script:LabStateDir '03-dns-record.txt'

Assert-LabHost -Allowed 'DC01'
Assert-Administrator

# Use the IP saved by break.ps1, otherwise the default.
$ip = $DefaultIPv4
if (Test-Path $stateFile) {
    $ip = (Get-Content -Path $stateFile).Trim()
    Remove-Item -Path $stateFile
}

$existing = Get-DnsServerResourceRecord -ZoneName $zone -Name $recordName -RRType A -ErrorAction SilentlyContinue
if ($existing) {
    Write-Output "$recordName.$zone already exists ($($existing.RecordData.IPv4Address)). Nothing to do."
} else {
    Add-DnsServerResourceRecordA -ZoneName $zone -Name $recordName -IPv4Address $ip
    Write-Output "Created $recordName.$zone -> $ip"
}

Resolve-DnsName -Name "$recordName.$zone" -Server 127.0.0.1 -DnsOnly
