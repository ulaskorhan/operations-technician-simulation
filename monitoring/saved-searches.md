# Useful Splunk searches

Run these in **Search & Reporting** on SPLUNK01. Set the time picker (for example *Last 24 hours*) before running.
Each search says which lab scenario produces matching events, so I can test it.

## Linux

### 1. Failed SSH logins (brute force)

```spl
index=linux sourcetype=linux_secure ("Failed password" OR "Invalid user")
| rex "from (?<src_ip>\d{1,3}(?:\.\d{1,3}){3})"
| stats count AS attempts, values(host) AS hosts, latest(_time) AS last_seen BY src_ip
| where attempts >= 5
| convert ctime(last_seen)
| sort - attempts
```

- `rex` pulls the source IP out of the raw text into a field called `src_ip`.
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

TODO: for each search, note whether it returned results in my lab and any changes I had to make to it.
TODO: which alert I created, how I triggered it, and how long it took to fire.
