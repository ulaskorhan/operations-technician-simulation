# Scenario 04 – GPO change tested on WS01

This one is a **change**, not a fault. The "customer" asks for a legal logon banner on their workstations.
I plan it as a change request, test it on WS01 only, verify it, and know how to roll it back.

The change: **Interactive logon: Message title / text for users attempting to log on**
(Computer Configuration → Policies → Windows Settings → Security Settings → Local Policies → Security Options).

## 1. Fill in the change request first

Copy [itil/change-template.md](../../../itil/change-template.md) to `itil/examples/CHG-0002-gpo-logon-banner.md`
and fill in sections 1–7 **before** making the change.

## 2. Prepare a test OU (on DC01)

WS01 should be in its own OU so the GPO only reaches it.

```powershell
New-ADOrganizationalUnit -Name 'Workstations' -Path 'OU=Lab,DC=lab,DC=local'
Get-ADComputer WS01 | Move-ADObject -TargetPath 'OU=Workstations,OU=Lab,DC=lab,DC=local'
```

## 3. Record the "before" state (on WS01)

```powershell
.\check.ps1
gpresult /r /scope:computer
```

## 4. Make the change (on DC01)

Either in **Group Policy Management** (GUI), or with PowerShell:

```powershell
$gpo = 'LAB - Logon banner'
$key = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System'

New-GPO -Name $gpo -Comment 'CHG-0002 legal logon banner'
Set-GPRegistryValue -Name $gpo -Key $key -ValueName 'legalnoticecaption' -Type String -Value 'Authorised use only'
Set-GPRegistryValue -Name $gpo -Key $key -ValueName 'legalnoticetext' -Type String -Value 'This system is for authorised users of lab.local only. Activity may be logged.'
New-GPLink -Name $gpo -Target 'OU=Workstations,OU=Lab,DC=lab,DC=local'
```

## 5. Test (on WS01)

```powershell
gpupdate /force
.\check.ps1
gpresult /r /scope:computer     # "LAB - Logon banner" should be under Applied Group Policy Objects
```

Then sign out: the banner should show before the logon screen.

## 6. Rollback (on DC01)

Disable the link first (fast and easy to undo), remove the GPO only when you are sure:

```powershell
Set-GPLink -Name 'LAB - Logon banner' -Target 'OU=Workstations,OU=Lab,DC=lab,DC=local' -LinkEnabled No
# later, if the change is cancelled for good:
# Remove-GPO -Name 'LAB - Logon banner'
```

On WS01, `gpupdate /force` and `.\check.ps1` should show the values are gone.

## 7. Document

Fill in [runbook.md](runbook.md) and section 8 (Result) of the change request.
