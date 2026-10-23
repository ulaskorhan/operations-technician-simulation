<#
.SYNOPSIS
    Shared safety checks for the Windows scenario scripts.

.DESCRIPTION
    Dot-source this file from a break/restore script:  . "$PSScriptRoot\..\LabSafety.ps1"
    The functions then become available inside that script.
#>

# Folder where break scripts save the "before" state, so restore can put it back.
$script:LabStateDir = 'C:\OpsLab\State'

# Stop unless this computer is one of the allowed lab machines.
function Assert-LabHost {
    param([Parameter(Mandatory)][string[]]$Allowed)
    if ($env:COMPUTERNAME -notin $Allowed) {
        throw "Computer '$env:COMPUTERNAME' is not allowed for this scenario (allowed: $($Allowed -join ', ')). Refusing to run."
    }
}

# Stop unless PowerShell runs "as Administrator".
function Assert-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Run this script in an elevated PowerShell (Run as Administrator).'
    }
}

# Ask the user to type "yes". Anything else stops the script without changes.
function Confirm-LabAction {
    param([Parameter(Mandatory)][string]$Message)
    Write-Output $Message
    $answer = Read-Host -Prompt "Type 'yes' to continue"
    if ($answer -ne 'yes') {
        Write-Output 'Aborted. Nothing was changed.'
        exit 0
    }
}

# Create the state folder if it does not exist yet.
function Initialize-LabStateDir {
    if (-not (Test-Path $script:LabStateDir)) {
        New-Item -Path $script:LabStateDir -ItemType Directory | Out-Null
    }
}
