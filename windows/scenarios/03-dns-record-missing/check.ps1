<#
.SYNOPSIS
    Scenario 03 - check (read-only): does intranet.lab.local resolve? Run on DC01 or WS01.
#>
[CmdletBinding()]
param(
    [string]$Name = 'intranet.lab.local',
    # DC01. TODO: change 192.168.100 to your lab subnet.
    [string]$DnsServer = '192.168.100.10'
)

# -DnsOnly skips the hosts file and NetBIOS, so we test the DNS server itself.
$answer = Resolve-DnsName -Name $Name -Server $DnsServer -Type A -DnsOnly -ErrorAction SilentlyContinue
if ($answer) { Write-Output "[ OK ] $Name resolves to $($answer.IPAddress -join ', ') on $DnsServer" }
else { Write-Output "[FAIL] $Name does not resolve on $DnsServer" }

# The client may have cached the old answer, or a "not found" answer. Show what is cached.
$cached = Get-DnsClientCache -Entry $Name -ErrorAction SilentlyContinue
if ($cached) { Write-Output "[INFO] Local cache has an entry for $Name (clear with: Clear-DnsClientCache or ipconfig /flushdns)" }
