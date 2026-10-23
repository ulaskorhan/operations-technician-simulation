# Windows

PowerShell scripts for DC01, SPLUNK01 and WS01. Copy this folder to `C:\OpsLab\repo\windows` on each machine
(or clone the repo there).

Run everything from an **elevated** PowerShell (Run as Administrator). Scripts downloaded from the internet are
blocked by default; allow them for the current window only:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
Get-ChildItem -Recurse C:\OpsLab\repo\windows | Unblock-File
```

## Scripts

| Script | Run on | What it does |
|--------|--------|--------------|
| [health-check.ps1](health-check.ps1) | Any | Stopped automatic services, low disk, System/Application errors (24 h), uptime, pending reboot. Text + CSV in `C:\OpsLab\Reports`. |
| [onboarding.ps1](onboarding.ps1) | DC01 | Creates AD users from [users.csv](users.csv), adds them to groups, logs to `C:\OpsLab\Logs\onboarding.log` |
| [offboarding.ps1](offboarding.ps1) | DC01 | Disables users, removes group memberships, moves them to `OU=Disabled Users`, logs to `C:\OpsLab\Logs\offboarding.log` |

### Prepare AD for onboarding/offboarding (once, on DC01)

```powershell
New-ADOrganizationalUnit -Name 'Lab' -Path 'DC=lab,DC=local'
New-ADOrganizationalUnit -Name 'Users' -Path 'OU=Lab,DC=lab,DC=local'
New-ADOrganizationalUnit -Name 'Groups' -Path 'OU=Lab,DC=lab,DC=local'
New-ADOrganizationalUnit -Name 'Disabled Users' -Path 'OU=Lab,DC=lab,DC=local'
'GRP-Operations', 'GRP-ServiceDesk', 'GRP-Network', 'GRP-VPN-Users' | ForEach-Object {
    New-ADGroup -Name $_ -GroupScope Global -GroupCategory Security -Path 'OU=Groups,OU=Lab,DC=lab,DC=local'
}
```

### Always dry-run first

```powershell
.\onboarding.ps1 -CsvPath .\users.csv -WhatIf
.\onboarding.ps1 -CsvPath .\users.csv
Get-ADUser -Filter * -SearchBase 'OU=Users,OU=Lab,DC=lab,DC=local' | Select-Object Name, Enabled

.\offboarding.ps1 -CsvPath .\users.csv -WhatIf
```

### Run the health check every morning (optional)

```powershell
$action  = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File C:\OpsLab\repo\windows\health-check.ps1'
$trigger = New-ScheduledTaskTrigger -Daily -At 07:00
Register-ScheduledTask -TaskName 'OpsLab Health Check' -Action $action -Trigger $trigger -User 'SYSTEM' -RunLevel Highest
```

## Scenarios

Same idea as the Linux scenarios: `check.ps1` (read-only), `break.ps1` (fault), `restore.ps1` (back to good state),
`runbook.md` (headings only, I fill it in). Shared safety functions are in [scenarios/LabSafety.ps1](scenarios/LabSafety.ps1):
every `break.ps1`/`restore.ps1` checks the computer name, needs Administrator, and `break.ps1` asks me to type `yes`.

| # | Folder | Run on | Ticket |
|---|--------|--------|--------|
| 01 | [01-service-stopped](scenarios/01-service-stopped/) | WS01 | "A user cannot print and the printers have disappeared." |
| 02 | [02-disk-full](scenarios/02-disk-full/) | WS01 | "The PC is slow and says the disk is almost full." |
| 03 | [03-dns-record-missing](scenarios/03-dns-record-missing/) | DC01 (break/restore), WS01 (check) | "Users cannot open http://intranet.lab.local." Run `restore.ps1` once first to create the record. |
| 04 | [04-gpo-change](scenarios/04-gpo-change/) | DC01 + WS01 | A change, not a fault: add a logon banner by GPO, test on WS01, roll back. See its README. |

## Linting

```powershell
Install-Module PSScriptAnalyzer -Scope CurrentUser
Invoke-ScriptAnalyzer -Path . -Recurse
```
