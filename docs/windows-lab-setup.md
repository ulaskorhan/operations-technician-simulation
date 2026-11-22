# Lab setup: DC01 and WS01

How to turn a fresh Windows Server install into the domain controller **DC01** for `lab.local`, and join
**WS01** to the domain. Run everything in PowerShell **as Administrator**.

Replace `192.168.182` with your own subnet if it is different (see
[lab-setup.md](lab-setup.md#0-find-your-subnet)). VMware NAT gateway = `.2`.

| Machine | IP | DNS server | Role |
|---------|----|------------|------|
| DC01 | 192.168.182.10 | itself (127.0.0.1 after promotion) | AD DS + DNS for lab.local |
| WS01 | 192.168.182.30 | 192.168.182.10 (DC01) | Domain member |

## How to tell DC01 is not set up yet

`ipconfig /all` on a finished DC shows `Host Name: DC01` and `Primary Dns Suffix: lab.local`.
A fresh install shows a random name (`WIN-XXXXXXX`), an empty primary DNS suffix and
`DNS Suffix Search List: localdomain` (that last one comes from VMware's DHCP).

## DC01

Take a VMware snapshot first (**VM → Snapshot → Take Snapshot**, name: `before-ad`).

### 1. Static IP

```powershell
Get-NetAdapter                       # note the adapter name, usually Ethernet0
New-NetIPAddress -InterfaceAlias "Ethernet0" -IPAddress 192.168.182.10 -PrefixLength 24 -DefaultGateway 192.168.182.2
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 192.168.182.2
```

The DNS server is VMware's for now. Promotion (step 4) changes it to the DC itself.

### 2. Rename and restart

```powershell
Rename-Computer -NewName DC01 -Restart
```

### 3. Install the AD DS role

```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
```

### 4. Create the forest (promotes the server to a DC and installs DNS)

```powershell
Install-ADDSForest -DomainName lab.local -DomainNetbiosName LAB -InstallDns
```

It asks for a DSRM (Directory Services Restore Mode) password. Store it in a password manager, not in
this repo. The server restarts by itself. Log in afterwards as `LAB\Administrator`.

### 5. Let DC01 resolve internet names

```powershell
Get-DnsServerForwarder                                # empty? then:
Add-DnsServerForwarder -IPAddress 192.168.182.2
```

DC01 answers for `lab.local` itself and forwards everything else to the VMware gateway.

### 6. Verify

```powershell
ipconfig /all                    # Host Name DC01, Primary Dns Suffix lab.local, DNS 127.0.0.1
Get-ADDomain | Select-Object DNSRoot, NetBIOSName
Get-Service DNS, NTDS, Netlogon
nslookup dc01.lab.local
nslookup -type=srv _ldap._tcp.dc._msdcs.lab.local
nslookup google.com
```

Take a snapshot: `dc-ready`.

## WS01

### 1. Static IP pointing at DC01 for DNS

```powershell
New-NetIPAddress -InterfaceAlias "Ethernet0" -IPAddress 192.168.182.30 -PrefixLength 24 -DefaultGateway 192.168.182.2
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 192.168.182.10
```

If the adapter already has a DHCP address, `New-NetIPAddress` may complain. Then set it in
`ncpa.cpl` → adapter → Properties → IPv4 instead.

### 2. Check DNS before joining

```powershell
nslookup dc01.lab.local          # Server: must be 192.168.182.10
Test-NetConnection 192.168.182.10 -Port 389    # LDAP on the DC
```

Joining fails with "An Active Directory Domain Controller for the domain could not be contacted" when
the client uses the wrong DNS server. That is the most common reason.

### 3. Rename and join

```powershell
Rename-Computer -NewName WS01 -Restart
# after the restart:
Add-Computer -DomainName lab.local -Credential LAB\Administrator -Restart
```

### 4. Verify

```powershell
whoami                           # after logging in as LAB\<user>
nltest /dsgetdc:lab.local        # which DC WS01 uses
gpresult /r                      # applied group policies
```

Take a snapshot: `ws-joined`.

> TODO: date I built the domain, and anything that went wrong on the way.
