# Network troubleshooting commands

Typical ticket: "a customer says the server is unreachable". This folder covers the commands I use to
answer it on macOS, Windows and Linux, and how to read what they print.

Practise with [practice-log.md](practice-log.md). Two existing break/fix scenarios cover DNS faults:
[Linux 08 – DNS resolution](../linux/scenarios/08-dns-resolution/) and
[Windows 03 – DNS record missing](../windows/scenarios/03-dns-record-missing/).

## The method: work up the layers

Each step only makes sense if the step before it worked.

| Step | Question | Command (Windows) | If it fails, suspect |
|------|----------|-------------------|----------------------|
| 1 | Do I have an IP, mask, gateway and DNS server? | `ipconfig /all` | Cable/vSwitch, DHCP, static config |
| 2 | Can I reach my own gateway? | `ping <gateway>` | Local network, VLAN, wrong subnet |
| 3 | Can I reach the target by IP? | `ping <ip>` | Routing, firewall, target down |
| 4 | Does the name resolve to the right IP? | `nslookup <name>` | DNS server, missing/wrong record, cache |
| 5 | Where does the path stop? | `tracert <ip>` | The hop after the last one that answers |
| 6 | Is the service port open? | `Test-NetConnection <host> -Port 443` | Service stopped, host firewall, wrong port |

Ping working proves the host is up. It does **not** prove the service works. Ping failing does **not**
prove the host is down: Windows Firewall blocks ICMP echo by default on many profiles. That is why
step 6 exists.

## Same job, three operating systems

| Job | macOS | Windows | Linux (Ubuntu) |
|-----|-------|---------|----------------|
| IP configuration | `ifconfig`, `ipconfig getifaddr en0` | `ipconfig /all`, `Get-NetIPConfiguration` | `ip a` (`ifconfig` is legacy) |
| Default gateway / routes | `netstat -rn`, `route get default` | `route print`, `ipconfig` | `ip r` |
| Which DNS server am I using? | `scutil --dns` | `ipconfig /all` | `resolvectl status` |
| Reachability | `ping -c 4 <host>` | `ping <host>` (4 by default) | `ping -c 4 <host>` |
| DNS lookup | `nslookup`, `dig` | `nslookup`, `Resolve-DnsName` | `dig`, `nslookup` (package `bind9-dnsutils`) |
| Lookup the way apps do it | `dscacheutil -q host -a name <host>` | `Resolve-DnsName <host>` | `getent hosts <host>` |
| Flush DNS cache | `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder` | `ipconfig /flushdns` | `resolvectl flush-caches` |
| Show DNS cache | – | `ipconfig /displaydns` | `resolvectl statistics` |
| Path to a host | `traceroute <host>` | `tracert <host>`, `pathping <host>` | `traceroute`, `tracepath`, `mtr` |
| Test a TCP port | `nc -zv <host> <port>` | `Test-NetConnection <host> -Port <port>` | `nc -zv <host> <port>` |
| Listening ports on this machine | `lsof -iTCP -sTCP:LISTEN -n -P` | `netstat -ano`, `Get-NetTCPConnection -State Listen` | `ss -tulpn` |
| ARP table (IP to MAC) | `arp -a` | `arp -a` | `ip neigh` |

## Reading the output

### ping

| Output | Meaning |
|--------|---------|
| `Reply from 192.168.100.10: bytes=32 time<1ms TTL=128` | Reachable. TTL 128 usually means Windows, 64 usually Linux/macOS |
| `Request timed out` | No reply came back: host down, ICMP blocked by a firewall, or the return path is broken |
| `Destination host unreachable` | A router (or your own machine) says there is no route, or ARP got no answer on the local subnet |
| `Ping request could not find host` / `cannot resolve` | DNS failed. The network may be fine: try the IP |
| Rising `time=` or some lost replies | Congestion or a bad link. Run a longer ping (`ping -t` on Windows, stop with Ctrl+C) |

### nslookup

```text
nslookup intranet.lab.local 192.168.100.10
Server:   dc01.lab.local          <- which DNS server answered
Address:  192.168.100.10

Name:     intranet.lab.local      <- the answer
Address:  192.168.100.50
```

| Output | Meaning |
|--------|---------|
| `Non-authoritative answer` | The answer came from a cache/recursive server, not the server that owns the zone. Normal for internet names |
| `*** ... can't find <name>: Non-existent domain` (NXDOMAIN) | The DNS server answered: this name does not exist. Check the record and the spelling |
| `DNS request timed out` / `no servers could be reached` | No answer from the DNS server: wrong server IP, server down, or port 53 blocked |
| Different answers from two servers | One has a stale or wrong record. Compare: `nslookup <name> <server1>` vs `<server2>` |

Useful forms:

```text
nslookup <name>                     # use my configured DNS server
nslookup <name> 8.8.8.8             # ask a specific server
nslookup 192.168.100.10             # reverse lookup (PTR): IP to name
nslookup -type=mx gmail.com         # mail servers
nslookup -type=srv _ldap._tcp.dc._msdcs.lab.local   # which domain controllers exist (AD depends on this)
```

**Important:** `nslookup` and `dig` talk straight to a DNS server. They ignore the hosts file and the
local DNS cache. Applications do not. If `nslookup` is right but the app is wrong, check the hosts file
(`C:\Windows\System32\drivers\etc\hosts`, `/etc/hosts`) and flush the cache. Use `Resolve-DnsName`
(Windows), `getent hosts` (Linux) or `dscacheutil` (macOS) to see what applications see.

### dig (Linux/macOS)

```text
dig intranet.lab.local @192.168.100.10        # ask DC01 directly
dig +short google.com                          # just the IP
dig -x 192.168.100.10                          # reverse lookup
```

Look at `status:` in the header: `NOERROR` = fine, `NXDOMAIN` = name does not exist,
`SERVFAIL` = the server failed to get an answer. The `ANSWER SECTION` holds the result and its TTL.

### tracert / traceroute

```text
tracert 8.8.8.8
  1    <1 ms    <1 ms    <1 ms  192.168.100.2     <- hop 1 is your gateway
  2     5 ms     4 ms     5 ms  10.0.0.1
  3     *        *        *     Request timed out.
  4    12 ms    11 ms    12 ms  8.8.8.8          <- reached the target
```

- Each line is one router (hop). Three times = three probes.
- `* * *` on a hop that is **followed by working hops** is normal: that router does not answer traceroute
  probes but forwards traffic.
- `* * *` from some hop **to the end** means the path stops there. The problem is at that hop or the next.
- Windows `tracert` uses ICMP. macOS/Linux `traceroute` uses UDP by default (`traceroute -I` for ICMP),
  so firewalls can treat them differently.
- `tracert -d` skips reverse DNS lookups and runs much faster.
- `pathping` (Windows) combines tracert and ping and shows packet loss per hop.
- In this lab (VMware NAT) the path inside the lab is one hop, and the NAT gateway may hide the hops
  beyond it. Running the same trace from the Mac shows the real path to the internet.

### Test-NetConnection (Windows)

```powershell
Test-NetConnection splunk01 -Port 9997
```

`TcpTestSucceeded : True` means something is listening and the firewall lets you in.
`False` with `PingSucceeded : True` means the host is up but the port is closed or blocked.

## Interview questions this answers

- "A user can't open a website. What do you check?" Walk the method table, out loud, in order.
- "Ping works by IP but not by name. What's wrong?" DNS: `nslookup`, check the DNS server in
  `ipconfig /all`, the record, the hosts file, flush the cache.
- "nslookup works but the browser doesn't." Hosts file, local cache, proxy, or the service/port (step 6).
- "Ping fails, is the server down?" Not necessarily: ICMP may be blocked. Test the port.
- "What does `* * *` in tracert mean?" See above.
- "Which port does DNS use?" 53, UDP for normal queries and TCP for large answers and zone transfers.
