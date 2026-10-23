# Skills matrix

Maps the Operations Technician (Orange Business, Operations Center) requirements to the exercises in this repo.
The **Status** column is mine to update after each exercise (TODO → Done, with the date).

## Requirements → exercises

| Requirement | Exercises | Evidence (link after done) | Status |
|-------------|-----------|----------------------------|--------|
| Handle events | Linux 02, 05, 07; Splunk alerts; `scripts/linux-healthcheck.sh` | TODO | TODO |
| Handle incidents | Linux 01–08; Windows 01–03; Kubernetes scenario; incident reports | TODO | TODO |
| Handle changes | Windows 04 (GPO); Ansible `update.yml` and `nginx.yml`; change requests | TODO | TODO |
| Implement changes and upgrades in customer systems | Ansible `update.yml` (patching, controlled reboot), `nginx.yml` | TODO | TODO |
| Troubleshooting | All scenarios | TODO | TODO |
| Customer contact | "Customer communication" section in every runbook and incident report | TODO | TODO |
| Windows servers | `health-check.ps1`, onboarding/offboarding, Windows scenarios | TODO | TODO |
| Unix/Linux servers | `linux/basics.md`, Linux scenarios 01–08 | TODO | TODO |
| Scripting and automation | Bash scenario scripts, health checks, PowerShell AD scripts | TODO | TODO |
| Ansible (preferred) | `ansible/playbooks/*.yml` | TODO | TODO |
| Kubernetes (preferred) | `kubernetes/` | TODO | TODO |
| Monitoring / logs | `monitoring/` (Splunk UF, saved searches, alert) | TODO | TODO |

## Commands and tools

Rate myself after the lab: 1 = needed to look it up, 2 = can do with notes, 3 = can do and explain without notes.

| Area | Tool / command | Before lab | After lab |
|------|----------------|------------|-----------|
| Linux services | `systemctl`, `journalctl` | TODO | TODO |
| Linux disk | `df`, `du`, `lsof`, `find -size` | TODO | TODO |
| Linux permissions | `chmod`, `chown`, `namei -l`, `sudo` | TODO | TODO |
| Linux processes | `top`, `ps`, `kill`, `nice`, `uptime` | TODO | TODO |
| Linux network | `ip`, `ss`, `dig`, `resolvectl`, `curl` | TODO | TODO |
| Linux scheduling | `cron`, `crontab`, `/etc/cron.d` | TODO | TODO |
| SSH | `ssh-keygen`, `authorized_keys`, `sshd -t`, `auth.log` | TODO | TODO |
| Windows | `Get-Service`, `Get-WinEvent`, `Get-CimInstance` | TODO | TODO |
| Active Directory | `New-ADUser`, `Disable-ADAccount`, `Move-ADObject` | TODO | TODO |
| Windows DNS / GPO | `Get-DnsServerResourceRecord`, `gpupdate`, `gpresult` | TODO | TODO |
| Ansible | `ansible`, `ansible-playbook --check --diff --limit` | TODO | TODO |
| Splunk | SPL searches, alerts, Universal Forwarder | TODO | TODO |
| Kubernetes | `kubectl get/describe/logs/scale/rollout` | TODO | TODO |
| ITIL | Incident report, change request, priority matrix | TODO | TODO |

## Suggested order (two days)

### Day 1 – Linux

| # | Exercise | Write in the runbook | Write in the lab journal |
|---|----------|----------------------|--------------------------|
| 1 | Lab setup check + `linux/basics.md` | – | Which commands were new; anything that did not work as the cheat sheet said |
| 2 | 01 service down | How I noticed (curl/check.sh), `systemctl status` and `is-enabled` output, why *enable* matters after a reboot | Difference between stopped and disabled |
| 3 | 02 disk full | Which commands found the file (`df -h`, `du -xh --max-depth=1`), how I decided it was safe to delete, what to do if the file was still open (`lsof +L1`) | Why you never just `rm` files in `/var` without checking |
| 4 | 03 config error | The exact `nginx -t` error line, how I found the line number, why `reload` is safer than `restart` | How to test a config before applying a change |
| 5 | 04 permissions | The 403 error in `/var/log/nginx/error.log`, `namei -l` output, correct owner/mode and why | How nginx's user (`www-data`) needs read and execute |
| 6 | 05 cron failing | Where cron logs went (`journalctl -t CRON`, `grep ops-lab-backup /var/log/syslog`), the root cause, the fix | How to test a cron job by hand before scheduling it |
| 7 | 06 SSH access | The `auth.log` line that showed the problem, which permissions sshd's StrictModes needs | How I would talk to a locked-out customer |
| 8 | 07 high load | `uptime`/`top` readings, how I found the PID and parent, `kill` vs `kill -9` | Load average vs CPU %, when to escalate before killing |
| 9 | 08 DNS resolution | `dig` vs `ping` results, `ls -l /etc/resolv.conf`, `resolvectl status`, the fix | How DNS is wired on Ubuntu 24.04 (systemd-resolved, stub resolver) |
| 10 | End of day 1 | – | Write one incident report in `itil/examples/` for the scenario I found hardest |

### Day 2 – Automation, Windows, monitoring, Kubernetes

| # | Exercise | Write in the runbook / document | Write in the lab journal |
|---|----------|---------------------------------|--------------------------|
| 1 | Ansible `ping.yml` | – | Inventory and SSH problems I hit |
| 2 | Ansible `healthcheck.yml` | – | What the report showed for each host |
| 3 | Ansible `update.yml` | Fill in the change request in `itil/examples/` before running it: risk, test with `--check --limit`, rollback (snapshot) | Which packages were upgraded, was a reboot needed |
| 4 | Ansible `nginx.yml` + `users.yml` | – | Output of the 1st vs 2nd run (idempotency: `changed=0` the second time) |
| 5 | `windows/health-check.ps1` | – | What it found on DC01 / SPLUNK01 / WS01 |
| 6 | Onboarding / offboarding | – | Run with `-WhatIf` first, then for real; log file contents |
| 7 | Windows 01 service stopped | Detection (health check / event 7036), fix, verification | |
| 8 | Windows 02 disk full | How I found the file, cleanup, how to prevent | |
| 9 | Windows 03 DNS record missing | `Resolve-DnsName` result, how I found the record was gone, fix | Difference between client cache and server record (`ipconfig /flushdns`) |
| 10 | Windows 04 GPO change | Change request: description, risk, test on WS01, rollback | `gpresult /r` before and after |
| 11 | Splunk forwarding | – | UF install steps, first events seen in `index=linux` |
| 12 | Splunk searches + alert | Turn one search into an alert, then trigger it with a Linux scenario | Did the alert fire, how long did it take |
| 13 | Kubernetes basics | – | `kubectl get/describe/logs` output, scaling up and down |
| 14 | Kubernetes scenario | Pod status, `describe` Events section, fix, verification | ImagePullBackOff vs CrashLoopBackOff |
| 15 | End of day 2 | – | Update this skills matrix (after-lab ratings) and the Status column |
