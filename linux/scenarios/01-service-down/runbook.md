# Runbook – 01 Service down (nginx)

Run on 2026-11-22. Environment: `ops-lnx01`, Ubuntu 24.04 in Multipass on my Mac (not the VMware lab,
which was too slow on my laptop that weekend). nginx 1.24.0.

## Scenario

`break.sh` stops and disables nginx. Ticket text: *"The website on ops-lnx01 is down."*

The script refused to run when I typed `y` instead of `yes` ("Aborted. Nothing was changed."),
so the confirmation safety check works as designed.

## Symptoms observed

```text
$ sudo ./check.sh
[FAIL] nginx is not running
[FAIL] nginx is not enabled at boot
[FAIL] http://localhost/ answers '000'

$ curl -I http://localhost
curl: (7) Failed to connect to localhost port 80 after 0 ms: Couldn't connect to server
```

`000` / "Couldn't connect" = no HTTP answer at all, so nothing is listening (not a 404 or 502 from a
running web server).

## Diagnosis steps

1. Confirm the symptom: `curl -I http://localhost` → couldn't connect (above).
2. Is anything listening on port 80?

   ```text
   $ sudo ss -tlnp | grep ':80'
   (no output)
   ```

   Nothing listens, so it is not a firewall/network problem: the web server is not running.
3. Service state:

   ```text
   $ systemctl status nginx --no-pager
   ○ nginx.service - A high performance web server and a reverse proxy server
        Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: enabled)
        Active: inactive (dead)
   ```

   `inactive (dead)` = stopped (a crash would say `failed`). `disabled` while `preset: enabled` =
   someone changed the default, so it would also stay down after a reboot.
4. Stopped or crashed?

   ```text
   $ journalctl -u nginx --no-pager -n 20
   Nov 22 09:42:14 ops-lnx01 systemd[1]: Stopping nginx.service - A high performance web server and a reverse proxy server...
   Nov 22 09:42:14 ops-lnx01 systemd[1]: nginx.service: Deactivated successfully.
   Nov 22 09:42:14 ops-lnx01 systemd[1]: Stopped nginx.service - A high performance web server and a reverse proxy server.
   ```

   A clean, controlled stop. No exit code, no error.
5. Who did it? `sudo grep nginx /var/log/auth.log` did **not** find it: sudo logs only the command that
   was typed (`./break.sh`), not what the script runs inside. Searching all sudo commands works:
   `sudo grep COMMAND /var/log/auth.log | tail -10`.
   Note: auth.log uses UTC (`08:42:14+00:00`), journalctl shows local time (`09:42:14` CET). Same moment.

## Root cause

nginx was stopped and disabled by a manual admin action (`break.sh` via sudo at 08:42:14 UTC), not by a
crash or a config error.

## Fix

```text
$ sudo systemctl enable --now nginx
Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service → /usr/lib/systemd/system/nginx.service.
```

`enable` recreates the boot link, `--now` also starts the service immediately.

## Verification

```text
$ systemctl status nginx --no-pager
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: enabled)
     Active: active (running) since Sun 2026-11-22 09:47:48 CET; 4s ago
    Process: 2850 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
   Main PID: 2853 (nginx)

$ curl -I http://localhost
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)

$ sudo ./check.sh
[ OK ] nginx is running
[ OK ] nginx is enabled at boot
[ OK ] http://localhost/ answers 200
```

`ExecStartPre` shows systemd runs `nginx -t` (config test) before every start: a broken config would
stop the start there (see scenario 03).

## Rollback / restore

`sudo ./restore.sh` returns the lab to a known good state after the exercise.

## Time taken

From the journal: fault at 09:42:14, service running again at 09:47:48 (about 5.5 minutes, including
reading the output carefully).

## Lessons learned

ubuntu is installed by using multipass on mac.
nginx 1.31.9 was installed. nginx is a web server and reverse proxy (represents the servers and handles inbound traffic.).
it was deliberately broken bu using the command "sudo ./break.sh"
time zone difference was noted "The journal shows 09:42, but auth.log shows 08:42:14+00:00" when i checked the commands, but before i toubleshooted with: 
- curl -I http://localhost
- systemctl status nginx --no-pager
- journalctl -u nginx --no-pager -n 20
- sudo grep nginx /var/log/auth.log | tail -5
and finally:
- sudo grep COMMAND /var/log/auth.log | tail -10
the grep COMMAND command showed that the nginx was deliberately broken. so,
- sudo systemctl enable --now nginx

double checked with:
- curl -I http://localhost
  and
- sudo ./check.sh

The result is: 

[ OK ] nginx is running
[ OK ] nginx is enabled at boot
[ OK ] http://localhost/ answers 200
