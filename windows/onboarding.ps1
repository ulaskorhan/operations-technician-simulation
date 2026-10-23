<#
.SYNOPSIS
    Create Active Directory users from a CSV file.

.DESCRIPTION
    For each row in the CSV:
      - skips the user if the SamAccountName already exists
      - creates the user in the OU from the CSV, enabled, with "must change password at next logon"
      - adds the user to the groups in the Groups column (separated by ;)
    Every action is written to a log file. Supports -WhatIf (shows what would happen, changes nothing).

    Run on DC01 (or a machine with RSAT) as a domain admin.

.EXAMPLE
    .\onboarding.ps1 -CsvPath .\users.csv -WhatIf

.EXAMPLE
    .\onboarding.ps1 -CsvPath .\users.csv
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$CsvPath,

    [string]$LogPath = 'C:\OpsLab\Logs\onboarding.log',

    # The part after @ in the user's logon name (UPN).
    [string]$UpnSuffix = 'lab.local'
)

# Stop at the first error unless we handle it ourselves with try/catch.
$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory

# Write a line with a timestamp to the log file and to the screen.
function Write-OpsLog {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR')][string]$Level = 'INFO'
    )
    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $LogPath -Value $line
    Write-Output $line
}

# Make sure the log folder exists.
$logDir = Split-Path -Path $LogPath -Parent
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory | Out-Null }

$users = Import-Csv -Path $CsvPath
Write-OpsLog "Onboarding started by $env:USERNAME, $($users.Count) row(s) in $CsvPath"

# Ask once for the initial password. -AsSecureString keeps it out of the screen and the history.
$initialPassword = Read-Host -Prompt 'Initial password for the new users' -AsSecureString

foreach ($row in $users) {
    $sam = $row.SamAccountName.Trim()

    # 1. Skip users that already exist.
    if (Get-ADUser -Filter "SamAccountName -eq '$sam'") {
        Write-OpsLog "$sam already exists, skipped" -Level WARN
        continue
    }

    # 2. Check the target OU exists before trying to create the user in it.
    try {
        Get-ADOrganizationalUnit -Identity $row.OU | Out-Null
    } catch {
        Write-OpsLog "$sam skipped: OU '$($row.OU)' not found" -Level ERROR
        continue
    }

    # 3. Create the user. A hashtable of parameters ("splatting") keeps the line readable.
    $newUser = @{
        Name                  = "$($row.FirstName) $($row.LastName)"
        GivenName             = $row.FirstName
        Surname               = $row.LastName
        DisplayName           = "$($row.FirstName) $($row.LastName)"
        SamAccountName        = $sam
        UserPrincipalName     = "$sam@$UpnSuffix"
        Department            = $row.Department
        Title                 = $row.Title
        Path                  = $row.OU
        AccountPassword       = $initialPassword
        Enabled               = $true
        ChangePasswordAtLogon = $true
    }

    if ($PSCmdlet.ShouldProcess($sam, "Create user in $($row.OU)")) {
        try {
            New-ADUser @newUser
            Write-OpsLog "$sam created in $($row.OU)"
        } catch {
            Write-OpsLog "$sam could not be created: $($_.Exception.Message)" -Level ERROR
            continue
        }
    }

    # 4. Add to groups. Split "GRP-A;GRP-B" into a list and ignore empty entries.
    $groups = $row.Groups -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    foreach ($group in $groups) {
        if ($PSCmdlet.ShouldProcess($sam, "Add to group $group")) {
            try {
                Add-ADGroupMember -Identity $group -Members $sam
                Write-OpsLog "$sam added to $group"
            } catch {
                Write-OpsLog "$sam could not be added to ${group}: $($_.Exception.Message)" -Level ERROR
            }
        }
    }
}

Write-OpsLog 'Onboarding finished'
