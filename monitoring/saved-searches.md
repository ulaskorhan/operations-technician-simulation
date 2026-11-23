# Useful Splunk searches

Run these in **Search & Reporting** on SPLUNK01. Set the time picker (for example *Last 24 hours*) before running.
Each search says which lab scenario produces matching events, so I can test it.

## Linux

### 1. Failed SSH logins (brute force)

```spl
index=linux sourcetype=linux_secure ("Failed password" OR "Invalid user")
| rex "from (?<src_ip>\S+) port"
| stats count AS attempts, values(host) AS hosts, latest(_time) AS last_seen BY src_ip
| where attempts >= 5
| convert ctime(last_seen)
| sort - attempts
```

- `rex` pulls the source IP out of the raw text into a field called `src_ip`. It takes whatever stands
  between `from` and `port`, so IPv6 addresses such as `::1` match too (an IPv4-only pattern missed them,
  see My results).
- `stats ... BY src_ip` gives one row per attacker IP.
- Test: from WS01, try `ssh wronguser@192.168.100.40` six times (with password login disabled you get "Invalid user" lines).

### 2. SSH key refused because of bad permissions (scenario 06)

```spl
index=linux sourcetype=linux_secure "Authentication refused"
| table _time, host, _raw
```

### 3. Service failures (scenarios 01 and 03)

```spl
index=linux sourcetype=syslog ("Failed with result" OR "Failed to start" OR "Main process exited")
| rex "(?<unit>[\w@.-]+\.service)"
| stats count, latest(_time) AS last_seen BY host, unit
| convert ctime(last_seen)
```

### 4. Disk warnings from the health check (scenario 02)

The health check writes `key=value` pairs, which Splunk turns into fields automatically.

```spl
index=linux sourcetype=syslog ops-healthcheck check=disk status=WARN
| stats latest(used_pct) AS used_pct, latest(_time) AS last_seen BY host, mount
| convert ctime(last_seen)
```

### 5. Failing cron job (scenario 05)

```spl
index=linux sourcetype=syslog ops-lab-backup ERROR
| stats count, latest(_raw) AS last_error BY host
```

### 6. Servers that stopped sending logs

A silent server can be a bigger problem than an error message.

```spl
| metadata type=hosts index=linux
| eval minutes_since = round((now() - lastTime) / 60)
| where minutes_since > 15
| convert ctime(lastTime)
| table host, lastTime, minutes_since
```

## Windows

### 7. Service stopped or start type changed (Windows scenario 01)

Event 7036 = service changed state, 7040 = start type changed.

```spl
index=wineventlog source="WinEventLog:System" (EventCode=7036 OR EventCode=7040)
| table _time, host, EventCode, Message
```

### 8. Low disk space (Windows scenario 02)

Event 2013 from source `srv` = "The disk is at or near capacity".

```spl
index=wineventlog source="WinEventLog:System" EventCode=2013
| table _time, host, Message
```

## Turn a search into an alert

Example: alert on failed SSH logins (search 1).

1. Run the search and check it returns what you expect.
2. **Save As → Alert**.
3. Title: `LAB - SSH brute force`. Permissions: *Private* (or *Shared in App*).
4. Alert type: **Scheduled**, *Run on Cron Schedule*, cron expression `*/5 * * * *` (every 5 minutes).
5. Time range: *Last 15 minutes* (a bit longer than the schedule, so nothing is missed between runs).
6. Trigger alert when: **Number of Results** *is greater than* `0`.
7. Trigger: **For each result** (one alert per source IP).
8. **Throttle**: tick it, suppress results containing field value `src_ip` for `30 minutes`, so one attacker does not create an alert every 5 minutes.
9. Trigger actions: **Add to Triggered Alerts** (email needs an SMTP server, which the lab does not have). Severity: *High*.
10. Save, then cause the event (six failed logins) and check **Activity → Triggered Alerts** after the next 5-minute run.

## My results

### 2026-11-23 – Search 1 logic, practised with grep on ops-lnx01

Splunk itself was not running (SPLUNK01 is in the VMware lab, which was too slow on my laptop).
I practised the same search logic on `/var/log/auth.log` of `ops-lnx01` (Ubuntu 24.04 in Multipass on
my Mac), the file that `inputs.conf` forwards as `index=linux sourcetype=linux_secure`.

Generate events (four logins with users that do not exist):

```text
$ for u in admin test oracle admin; do ssh -o BatchMode=yes -o StrictHostKeyChecking=no $u@localhost true; done
admin@localhost: Permission denied (publickey).
test@localhost: Permission denied (publickey).
oracle@localhost: Permission denied (publickey).
admin@localhost: Permission denied (publickey).
```

`(publickey)` = the server only accepts SSH keys, no passwords.

Search (Splunk: `index=linux sourcetype=linux_secure "Invalid user"`):

```text
$ sudo grep "Invalid user" /var/log/auth.log | tail -5
2026-11-23T07:40:36.223581+00:00 ops-lnx01 sshd[10975]: Invalid user admin from ::1 port 34404
2026-11-23T07:40:36.420699+00:00 ops-lnx01 sshd[10978]: Invalid user test from ::1 port 34412
2026-11-23T07:40:36.583959+00:00 ops-lnx01 sshd[10981]: Invalid user oracle from ::1 port 34424
2026-11-23T07:40:36.713762+00:00 ops-lnx01 sshd[10984]: Invalid user admin from ::1 port 34434
2026-11-23T07:40:55.206092+00:00 ops-lnx01 sudo:   ubuntu : TTY=pts/0 ; PWD=/home/ubuntu/operations-technician-simulation/monitoring ; USER=root ; COMMAND=/usr/bin/grep 'Invalid user' /var/log/auth.log
```

Count per user (Splunk: `| stats count by user | sort - count`):

```text
$ sudo grep "Invalid user" /var/log/auth.log | awk '{print $(NF-4)}' | sort | uniq -c | sort -rn
      3 ;
      2 admin
      1 test
      1 oracle
```

**What went wrong:** the `;` rows are not users. sudo logs every command to auth.log, and my own
`grep 'Invalid user'` command contains the search text, so each search added a matching sudo line.
`awk` then picked the wrong word out of those lines. Counting per source IP had the same problem
(`4 ::1` and `4 'Invalid`).

**Fix:** only match lines from sshd:

```bash
sudo grep "sshd.*Invalid user" /var/log/auth.log | awk '{print $(NF-4)}' | sort | uniq -c | sort -rn
```

TODO: paste the output of the fixed command.

**What this changed in the Splunk search:** always narrow by source and process, not free text alone
(`index=linux sourcetype=linux_secure process=sshd "Invalid user"`). The attempts came from `::1`
(IPv6 localhost), which the old IPv4-only `rex` in search 1 would not have extracted, so I changed it
to take whatever stands between `from` and `port`.

**What I learned:**

Splunk is a platform for log data. It is mainly used for security (for example in a SOC) and for IT
operations (for example in an operations center like Orange Business). Splunk makes log data searchable,
and every event comes with its host, source, sourcetype and time. In IT operations, Splunk helps answer
questions such as: Is the server down? Is the disk full? Why did a service fail last night? How many
errors does an application produce?

In my example I counted failed logins, and the results were wrong. My search also matched my own sudo
commands in auth.log. So it is important to narrow a search by source and process. In Splunk that means
using `index`, `sourcetype` and a field such as `process=sshd`, not just free text.

TODO: run the searches in Splunk on SPLUNK01, and note which alert I created, how I triggered it and
how long it took to fire.
