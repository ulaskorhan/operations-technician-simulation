# Runbook – 02 Disk full (/var)

Run on 2026-11-22. Environment: `ops-lnx01`, Ubuntu 24.04 in Multipass on my Mac, 15 GB virtual disk.

## Scenario

`break.sh` fills `/var` to about 97% with one large file. Ticket text:
*"Monitoring alert: /var on ops-lnx01 is almost full."*

Baseline before the fault:

```text
$ sudo ./check.sh
[ OK ] /var is 15% used (threshold 90%)
```

## Symptoms observed

```text
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        14G   14G  415M  97% /
/dev/sda16      891M   61M  768M   8% /boot
/dev/sda15       98M  6.4M   92M   7% /boot/efi
(tmpfs lines left out)
```

`/var` is not a separate filesystem here, it is part of `/`. So the whole root filesystem had only
415 MB left, not just the logs: services, logins and package installs can all fail when `/` is full.

## Diagnosis steps

1. Which folder uses the space? (`-x` = stay on this filesystem, `sort -h` = biggest at the bottom)

   ```text
   $ sudo du -xh --max-depth=1 /var | sort -h
   4.0K	/var/backups
   ...
   157M	/var/cache
   260M	/var/lib
   12G	/var
   12G	/var/log
   ```

   I first read `/var/backups` as the problem because it was at the top. With `sort -h` the smallest
   is at the top: `/var/backups` is 4 KB, `/var/log` is the 12 GB one.
2. Find the large file directly:

   ```text
   $ sudo find /var -xdev -type f -size +100M -exec ls -lh {} \;
   -rw-r--r-- 1 root root 12G Nov 22 10:41 /var/log/lab-app/debug.log
   ```

3. Before removing anything: what is the file, and does a process still have it open?
   `sudo lsof /var/log/lab-app/debug.log` (no output = nothing has it open).

## Root cause

A single debug log, `/var/log/lab-app/debug.log`, had grown to 12 GB.

## Fix

Chosen fix: empty the log instead of deleting it.

```bash
sudo truncate -s 0 /var/log/lab-app/debug.log
```

Why `truncate` and not `rm`: if a program still has a log open, `rm` only removes the name. The space
is not freed until the program closes the file, so `df` would still show 97%. `truncate` frees the space
straight away and the program can keep writing to the same file. It only makes sense for logs: on a
database or other data file it would destroy the data. If the content may be needed, save the end first
(`tail -n 1000 ... > ~/debug-tail.log`).

TODO: paste the output of `lsof` and `truncate` from my run.

## Verification

```text
$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        14G  2.4G   12G  18% /
```

## Follow-on problem the next day

The disk being full had a side effect I only found later. Installing Ansible failed:

```text
$ sudo apt install ansible-core
You might want to run 'apt --fix-broken install' to correct these.
The following packages have unmet dependencies:
 ansible-core : Depends: python3-resolvelib (< 1.1.0) but it is not going to be installed
 ...
 linux-image-6.8.0-149-generic : Depends: linux-modules-6.8.0-149-generic but it is not going to be installed
E: Unmet dependencies. Try 'apt --fix-broken install' with no packages (or specify a solution).
```

The `linux-image` line is the clue: an automatic kernel update (unattended-upgrades) ran while the disk
was full and stopped halfway, leaving apt in a broken state that blocked every other install. Fixed with
`sudo apt --fix-broken install -y` after checking that the disk had space again, then
`sudo apt install -y ansible` worked.

## Rollback / restore

`sudo ./restore.sh` removes the fill file and returns the lab to a known good state.

## Lessons learned

TODO: in my own words.
