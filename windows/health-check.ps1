<#
.SYNOPSIS
    Basic health check for a Windows server or client.

.DESCRIPTION
    Checks:
      1. Automatic services that are not running
      2. Fixed disks with low free space
      3. Errors and critical events in the System and Application logs (last 24 hours)
      4. Uptime
      5. Pending reboot
    Prints a readable report and saves it as a .txt and a .csv file.
    Exit code 0 = everything OK, 1 = at least one WARN or FAIL.

.EXAMPLE
    .\health-check.ps1

.EXAMPLE
    .\health-check.ps1 -OutputDir C:\Temp -DiskWarnPercent 20
#>
[CmdletBinding()]
param(
    # Folder for the .txt and .csv reports.
    [string]$OutputDir = 'C:\OpsLab\Reports',

    # Warn when a disk has less than this many percent free.
    [int]$DiskWarnPercent = 15,

    # How far back to look in the event logs.
    [int]$EventHours = 24,

    # Warn when the machine has not rebooted for this many days (often means missing patches).
    [int]$UptimeWarnDays = 30,

    # Automatic services that are normally stopped (delayed or trigger start). Adjust after the first run.
    [string[]]$IgnoreService = @('sppsvc', 'RemoteRegistry', 'MapsBroker', 'edgeupdate', 'gupdate', 'WbioSrvc')
)

# A list that collects one object per finding. Each object becomes one row in the CSV.
$results = [System.Collections.Generic.List[object]]::new()

function Add-Result {
    param(
        [string]$Check,
        [string]$Item,
        [ValidateSet('OK', 'WARN', 'FAIL', 'INFO')][string]$Status,
        [string]$Detail
    )
    $results.Add([pscustomobject]@{
        Computer = $env:COMPUTERNAME
        Check    = $Check
        Item     = $Item
        Status   = $Status
        Detail   = $Detail
    })
}

# ---- 1. Automatic services that are not running ---------------------------------
# Win32_Service gives StartMode (Auto/Manual/Disabled) and State (Running/Stopped).
$stopped = Get-CimInstance -ClassName Win32_Service |
    Where-Object { $_.StartMode -eq 'Auto' -and $_.State -ne 'Running' -and $_.Name -notin $IgnoreService }

if ($stopped) {
    foreach ($svc in $stopped) {
        Add-Result -Check 'Service' -Item $svc.Name -Status 'FAIL' -Detail "$($svc.DisplayName) is $($svc.State) (StartMode Auto)"
    }
} else {
    Add-Result -Check 'Service' -Item 'All automatic services' -Status 'OK' -Detail 'Running'
}

# ---- 2. Disk space ---------------------------------------------------------------
# DriveType 3 = local fixed disk.
$disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 3'
foreach ($disk in $disks) {
    $freePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 1)
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 1)
    $sizeGB = [math]::Round($disk.Size / 1GB, 1)
    $status = if ($freePercent -lt $DiskWarnPercent) { 'WARN' } else { 'OK' }
    Add-Result -Check 'Disk' -Item $disk.DeviceID -Status $status -Detail "$freeGB GB free of $sizeGB GB ($freePercent%)"
}

# ---- 3. Event log errors ---------------------------------------------------------
# Level 1 = Critical, 2 = Error. Get-WinEvent throws an error when nothing matches,
# so -ErrorAction SilentlyContinue turns "no events" into an empty result.
$since = (Get-Date).AddHours(-$EventHours)
foreach ($log in 'System', 'Application') {
    $events = Get-WinEvent -FilterHashtable @{ LogName = $log; Level = 1, 2; StartTime = $since } -ErrorAction SilentlyContinue

    if (-not $events) {
        Add-Result -Check "EventLog $log" -Item 'Errors' -Status 'OK' -Detail "No errors in the last $EventHours h"
        continue
    }

    # Group the same source + event ID together, so 200 identical errors become one line.
    $groups = $events | Group-Object -Property ProviderName, Id | Sort-Object -Property Count -Descending
    foreach ($group in $groups) {
        $latest = $group.Group | Sort-Object -Property TimeCreated -Descending | Select-Object -First 1
        # Only the first line of the message, to keep the report readable.
        $firstLine = ($latest.Message -split "`r?`n")[0]
        Add-Result -Check "EventLog $log" -Item "$($latest.ProviderName) ID $($latest.Id)" -Status 'WARN' `
            -Detail "$($group.Count)x, latest $($latest.TimeCreated.ToString('yyyy-MM-dd HH:mm')): $firstLine"
    }
}

# ---- 4. Uptime -------------------------------------------------------------------
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$uptime = (Get-Date) - $os.LastBootUpTime
$uptimeText = '{0}d {1}h {2}m' -f $uptime.Days, $uptime.Hours, $uptime.Minutes
$status = if ($uptime.TotalDays -gt $UptimeWarnDays) { 'WARN' } else { 'INFO' }
Add-Result -Check 'Uptime' -Item $os.Caption -Status $status -Detail "Up $uptimeText (last boot $($os.LastBootUpTime))"

# ---- 5. Pending reboot -----------------------------------------------------------
# Windows records a needed reboot in a few different places in the registry.
$reasons = @()
if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') {
    $reasons += 'Component Based Servicing'
}
if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') {
    $reasons += 'Windows Update'
}
$sessionManager = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -ErrorAction SilentlyContinue
if ($sessionManager.PendingFileRenameOperations) {
    $reasons += 'Pending file rename'
}

if ($reasons) {
    Add-Result -Check 'Reboot' -Item 'Pending reboot' -Status 'WARN' -Detail ($reasons -join ', ')
} else {
    Add-Result -Check 'Reboot' -Item 'Pending reboot' -Status 'OK' -Detail 'No reboot pending'
}

# ---- Output ----------------------------------------------------------------------
if (-not (Test-Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory | Out-Null
}
$stamp = Get-Date -Format 'yyyyMMdd-HHmm'
$baseName = Join-Path $OutputDir "$env:COMPUTERNAME-healthcheck-$stamp"

$problems = @($results | Where-Object { $_.Status -in 'WARN', 'FAIL' })
$header = @(
    "Health check for $env:COMPUTERNAME - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    "Problems found: $($problems.Count)"
    ''
)
$table = $results | Format-Table -Property Status, Check, Item, Detail -AutoSize -Wrap | Out-String -Width 220

# Show on screen, then save the same text and a CSV.
$header + $table | Write-Output
$header + $table | Out-File -FilePath "$baseName.txt" -Encoding utf8
$results | Export-Csv -Path "$baseName.csv" -NoTypeInformation -Encoding UTF8

Write-Output "Report saved: $baseName.txt and $baseName.csv"

# Non-zero exit code if there is anything to look at (useful for scheduled tasks and monitoring).
if ($problems.Count -gt 0) { exit 1 } else { exit 0 }
