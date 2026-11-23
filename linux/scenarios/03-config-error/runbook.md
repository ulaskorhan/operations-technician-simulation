# Runbook – 03 nginx configuration error

Run on 2026-11-23. Environment: `ops-lnx01`, Ubuntu 24.04 in Multipass on my Mac, nginx 1.24.0.

## Scenario

`break.sh` removes the `;` at the end of `listen 80 default_server` in the site config and restarts
nginx. Ticket text: *"After a colleague's change, the website on ops-lnx01 is down."*

## Symptoms observed

TODO: paste `sudo ./check.sh` and `systemctl status nginx` output from my run.

## Diagnosis steps

Test the configuration. I chained the test and the restart with `&&`, so the restart only runs if the
test passes:

```text
$ sudo nginx -t && sudo systemctl restart nginx && sudo ./check.sh
2026/11/23 07:58:13 [emerg] 4863#4863: invalid parameter "listen" in /etc/nginx/sites-enabled/default:23
nginx: configuration file /etc/nginx/nginx.conf test failed
```

- The test failed, so `&&` stopped there: no restart was attempted with a broken config.
- `/etc/nginx/sites-enabled/default` is a symlink to `/etc/nginx/sites-available/default`, the same file.
- The error points at **line 23**, but the mistake is on **line 22**. nginx reads until it meets a `;`.
  Without one at the end of line 22, it reads lines 22 and 23 as one directive:
  `listen 80 default_server listen [::]:80 default_server;` so the second `listen` becomes an
  "invalid parameter". An error on line N often means something is missing at the end of line N-1.

To see it: `sudo sed -n '21,23p' /etc/nginx/sites-enabled/default`

## Root cause

A missing `;` at the end of `listen 80 default_server` (line 22) after a config change.

## Fix

Add the `;` back:

```bash
sudo nano -l +22 /etc/nginx/sites-available/default
```

Then test again before restarting:

```bash
sudo nginx -t && sudo systemctl restart nginx && sudo ./check.sh
```

## Verification

TODO: paste the `nginx -t` "syntax is ok / test is successful" output and `check.sh` result from my run.

## Rollback / restore

`sudo ./restore.sh` puts back the backup of the original config that `break.sh` saved.

## Prevention

The Ansible playbook `nginx.yml` runs `nginx -t` before its reload handler, so a broken template stops
the play instead of taking nginx down. systemd also runs `nginx -t` as `ExecStartPre` on every start
(seen in scenario 01).

## Lessons learned

TODO: in my own words.
