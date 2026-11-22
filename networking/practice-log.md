# Network commands – practice log

Run each exercise on the machines listed and paste the **real** output (shorten long output with `...`).
Then write one line on what the output tells you. Reference: [README.md](README.md).

Lab subnet in the examples: `192.168.100.0/24` (change to yours, see
[lab-setup.md](../docs/lab-setup.md#0-find-your-subnet)). VMware NAT gateway is usually `.2`.

| Machine | Where |
|---------|-------|
| Mac | Host computer (outside the lab, real home network) |
| WS01 | Windows VM, 192.168.100.30 |
| DC01 | Windows Server VM, 192.168.100.10 (DNS for lab.local) |
| OPS-LNX01 | Ubuntu VM, 192.168.100.40 |

---

## Exercise 1 – Know your own configuration

Mac: `ifconfig en0`, `netstat -rn | grep default`, `scutil --dns | grep nameserver`
WS01: `ipconfig /all`
OPS-LNX01: `ip a`, `ip r`, `resolvectl status`

```text
TODO: paste output
```

| Machine | IP / mask | Gateway | DNS server |
|---------|-----------|---------|------------|
| Mac | TODO | TODO | TODO |
| WS01 | TODO | TODO | TODO |
| OPS-LNX01 | TODO | TODO | TODO |

What I noticed: TODO (for example: why the Mac and the VMs have different gateways)

## Exercise 2 – ping, layer by layer

From WS01 and from OPS-LNX01, in this order:

1. `ping <own gateway>`
2. `ping 192.168.100.10` (DC01)
3. `ping 8.8.8.8`
4. `ping google.com`
5. `ping dc01.lab.local`

```text
TODO: paste output
```

Which TTL did DC01 reply with, and what does it tell me? TODO
Did any ping fail? Why? TODO

## Exercise 3 – nslookup and dig

From WS01:

```text
nslookup dc01.lab.local
nslookup google.com
nslookup google.com 8.8.8.8
nslookup 192.168.100.10
nslookup -type=srv _ldap._tcp.dc._msdcs.lab.local
nslookup doesnotexist.lab.local
```

From OPS-LNX01: `dig dc01.lab.local @192.168.100.10`, `dig +short google.com`, `dig -x 192.168.100.10`

From the Mac: `nslookup dc01.lab.local` (expected to fail: why?)

Mac (home network, 2026-11-21):

```text
% nslookup google.com
Server:		2001:4600:4:fff::253
Address:	2001:4600:4:fff::253#53

Non-authoritative answer:
Name:	google.com
Address: 172.217.19.238

% nslookup google.com 8.8.8.8
Server:		8.8.8.8
Address:	8.8.8.8#53

Non-authoritative answer:
Name:	google.com
Address: 172.217.19.238

% nslookup dc01.lab.local
Server:		2001:4600:4:fff::253
Address:	2001:4600:4:fff::253#53

** server can't find dc01.lab.local: NXDOMAIN
```

WS01 / OPS-LNX01:

```text
TODO: paste output
```

- Which server answered each query (the `Server:` line)? TODO
- Which answers were "Non-authoritative", and why? TODO
- What did the non-existent name return? TODO
- Did the reverse lookup work? If not, is there a reverse lookup zone on DC01? TODO
- Why does the Mac not resolve lab.local? TODO

## Exercise 4 – nslookup vs what applications see

On WS01 (as administrator), add a test line to the hosts file, then compare:

```powershell
Add-Content C:\Windows\System32\drivers\etc\hosts "192.168.100.40 hosts-test.lab.local"
nslookup hosts-test.lab.local
Resolve-DnsName hosts-test.lab.local
ping hosts-test.lab.local
# clean up: open the hosts file in Notepad as administrator and delete the line, then:
ipconfig /flushdns
```

```text
TODO: paste output
```

Why did nslookup and Resolve-DnsName give different results? TODO

## Exercise 5 – tracert / traceroute

- Mac: `traceroute 8.8.8.8`
- WS01: `tracert -d 8.8.8.8`, `tracert 192.168.100.10`, `pathping -n 8.8.8.8` (takes a few minutes)
- OPS-LNX01: `tracepath 8.8.8.8` (or `sudo apt install traceroute`, then `traceroute 8.8.8.8`)

Mac (home network, 2026-11-21; my ISP gateway address is masked, stopped with Ctrl+C at hop 6):

```text
% ping -c 4 8.8.8.8
64 bytes from 8.8.8.8: icmp_seq=0 ttl=117 time=24.252 ms
64 bytes from 8.8.8.8: icmp_seq=1 ttl=117 time=19.907 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=117 time=19.986 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=117 time=16.636 ms
4 packets transmitted, 4 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 16.636/20.195/24.252/2.704 ms

% traceroute 8.8.8.8
traceroute to 8.8.8.8 (8.8.8.8), 64 hops max, 40 byte packets
 1  192.168.68.1 (192.168.68.1)  12.236 ms  5.257 ms  5.349 ms
 2  xxxxxxxx-gw.ti.telenor.net (88.91.x.x)  7.361 ms  5.681 ms  5.566 ms
 3  * * *
 4  ti3219b320-ae3-0.ti.telenor.net (146.172.105.122)  21.920 ms  12.428 ms  13.592 ms
 5  148.122.10.54 (148.122.10.54)  15.078 ms  14.375 ms  14.136 ms
 6  *^C
```

WS01 / OPS-LNX01:

```text
TODO: paste output
```

- How many hops to DC01, and why? TODO
- Where is the first hop on the Mac vs WS01? TODO
- Did any hop show `* * *`? Did the trace continue after it? TODO
- Why might the Mac and the VM traces look different? TODO

## Exercise 6 – Is the service actually up? (ports)

WS01:

```powershell
Test-NetConnection 192.168.100.20 -Port 9997    # Splunk receiving
Test-NetConnection 192.168.100.40 -Port 80      # nginx on OPS-LNX01
Test-NetConnection 192.168.100.40 -Port 22      # SSH
Test-NetConnection 192.168.100.40 -Port 8080    # nothing listens here
```

OPS-LNX01: `sudo ss -tulpn`, `nc -zv 192.168.100.20 9997`
Mac: `nc -zv 192.168.100.40 22` (works only if the Mac can reach the VMware NAT network)

```text
TODO: paste output
```

What is the difference between the 8080 result and the 80 result? TODO

## Exercise 7 – Put it together on a real fault

Run [Linux 08 – DNS resolution](../linux/scenarios/08-dns-resolution/) or
[Windows 03 – DNS record missing](../windows/scenarios/03-dns-record-missing/). Troubleshoot it with the
method from the README and fill in that scenario's `runbook.md`.

Which commands found the fault fastest? TODO

## What I learned

TODO: fill in after the exercises, in my own words.
