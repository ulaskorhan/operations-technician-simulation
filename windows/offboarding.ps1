<#
.SYNOPSIS
    Disable Active Directory users from a CSV file.

.DESCRIPTION
    For each SamAccountName in the CSV:
      - disables the account
      - writes "Disabled <date> by <admin>" in the Description field
      - removes the user from all groups (Domain Users stays, it is the primary group)
        and writes the removed groups to the log, so they can be added back if needed
      - moves the user to the Disabled Users OU
    The account is NOT deleted. Supports -WhatIf.

    Run on DC01 (or a machine with RSAT) as a domain admin.

.EXAMPLE
    .\offboarding.ps1 -CsvPath .\users.csv -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$CsvPath,

    [string]$DisabledOU = 'OU=Disabled Users,OU=Lab,DC=lab,DC=local',

    [string]$LogPath = 'C:\OpsLab\Logs\offboarding.log'
)

$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR')][string]$Level = 'INFO'
    )
    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $LogPath -Value $line
    Write-Output $line
}

$logDir = Split-Path -Path $LogPath -Parent
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory | Out-Null }

# Check the target OU exists before touching any user.
Get-ADOrganizationalUnit -Identity $DisabledOU | Out-Null

$rows = Import-Csv -Path $CsvPath
Write-Log "Offboarding started by $env:USERNAME, $($rows.Count) row(s) in $CsvPath"

foreach ($row in $rows) {
    $sam = $row.SamAccountName.Trim()

    # -Properties MemberOf asks AD to also return the list of groups.
    $user = Get-ADUser -Filter "SamAccountName -eq '$sam'" -Properties MemberOf
    if (-not $user) {
        Write-Log "$sam not found, skipped" -Level WARN
        continue
    }

    if ($PSCmdlet.ShouldProcess($sam, 'Disable account')) {
        Disable-ADAccount -Identity $user
        Set-ADUser -Identity $user -Description "Disabled $(Get-Date -Format 'yyyy-MM-dd') by $env:USERNAME"
        Write-Log "$sam disabled"
    }

    foreach ($groupDn in $user.MemberOf) {
        if ($PSCmdlet.ShouldProcess($sam, "Remove from $groupDn")) {
            # -Confirm:$false: do not ask for every single group.
            Remove-ADGroupMember -Identity $groupDn -Members $user -Confirm:$false
            Write-Log "$sam removed from $groupDn"
        }
    }

    if ($PSCmdlet.ShouldProcess($sam, "Move to $DisabledOU")) {
        Move-ADObject -Identity $user.DistinguishedName -TargetPath $DisabledOU
        Write-Log "$sam moved to $DisabledOU"
    }
}

Write-Log 'Offboarding finished'
