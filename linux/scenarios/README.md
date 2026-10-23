# Linux break/fix scenarios

Each scenario folder has four files:

| File | What it does | Changes the system? |
|------|--------------|---------------------|
| `check.sh` | Read-only health check for this scenario. Prints `[ OK ]` or `[FAIL]` lines. | No |
| `break.sh` | Injects the fault. Checks hostname, asks for confirmation, saves the "before" state. | Yes |
| `restore.sh` | Puts the machine back to a known good state, even if my own fix was incomplete. | Yes |
| `runbook.md` | Headings only. I fill it in after doing the exercise. | – |

All `break.sh` and `restore.sh` scripts use the shared safety functions in [lib/safety.sh](lib/safety.sh):
they only run on `ops-lnx01` or `ops-lnx02`, they need `sudo`, and `break.sh` asks me to type `yes`.
Saved state goes in `/var/lib/ops-lab/`.

## How to run one

```bash
cd linux/scenarios/01-service-down
sudo ./check.sh       # healthy state: everything OK
sudo ./break.sh       # inject the fault
# Troubleshoot WITHOUT reading break.sh first. Treat it as a ticket:
# "Customer reports the website on OPS-LNX01 is down."
sudo ./check.sh       # after my fix: should be all OK again
sudo ./restore.sh     # always run, to be sure the lab is clean
```

## The scenarios

The "ticket" column is what I pretend the customer or monitoring told me. I should not read `break.sh` before trying.

| # | Folder | Ticket | Prerequisite |
|---|--------|--------|--------------|
| 01 | [01-service-down](01-service-down/) | "The website is down." | nginx installed |
| 02 | [02-disk-full](02-disk-full/) | "Monitoring: /var is almost full." | – |
| 03 | [03-config-error](03-config-error/) | "After a colleague's change, the website will not start." | nginx installed |
| 04 | [04-permissions](04-permissions/) | "The website shows 403 Forbidden." | nginx installed |
| 05 | [05-cron-failing](05-cron-failing/) | "The nightly backup job is not producing files." | – |
| 06 | [06-ssh-access](06-ssh-access/) | "User labuser cannot log in with SSH any more." | `labuser` with a key (see lab-setup step 6) |
| 07 | [07-high-load](07-high-load/) | "The server is very slow." | – |
| 08 | [08-dns-resolution](08-dns-resolution/) | "The server cannot reach anything by name." | – |

If something goes badly wrong: run `restore.sh`, and if that does not help, revert to the "clean baseline" VMware snapshot.
