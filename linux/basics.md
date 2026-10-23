# Linux basics – cheat sheet

Commands I practise before the scenarios. Run them on OPS-LNX01 and try each one yourself.
Add your own notes under **My notes** as you go.

## Services – `systemctl`

```bash
systemctl status nginx            # running? recent log lines, main PID
sudo systemctl start nginx        # start now
sudo systemctl stop nginx         # stop now
sudo systemctl restart nginx      # stop + start (short downtime)
sudo systemctl reload nginx       # re-read config without dropping connections
sudo systemctl enable nginx       # start at boot
sudo systemctl disable nginx      # do not start at boot
sudo systemctl enable --now nginx # enable and start in one go
systemctl is-active nginx         # prints active / inactive / failed
systemctl is-enabled nginx        # prints enabled / disabled
systemctl --failed                # all units in failed state
systemctl list-units --type=service --state=running
systemctl cat nginx               # show the unit file
```

## Logs – `journalctl`

```bash
journalctl -u nginx                   # all logs for one unit
journalctl -u nginx -n 50 --no-pager  # last 50 lines
journalctl -u nginx -f                # follow live (Ctrl+C to stop)
journalctl -u nginx --since "10 min ago"
journalctl -p err -b                  # errors (and worse) since this boot
journalctl -t CRON --since today      # by tag (syslog identifier)
journalctl -k                         # kernel messages
journalctl --disk-usage
less /var/log/syslog                  # classic text logs (rsyslog)
sudo tail -f /var/log/auth.log        # logins, sudo, ssh
```

## Users and groups

```bash
whoami; id                            # who am I, which groups
id labuser
getent passwd labuser                 # user entry (name:x:uid:gid:comment:home:shell)
sudo adduser alice                    # interactive, creates home
sudo useradd -m -s /bin/bash bob      # non-interactive
sudo passwd bob
sudo usermod -aG sudo bob             # ADD to group (-a is important, without it other groups are removed)
sudo gpasswd -d bob sudo              # remove from group
sudo usermod -L bob                   # lock account
sudo userdel -r bob                   # delete user and home
groups bob
getent group sudo
last -n 10                            # recent logins
```

## Permissions – `chmod`, `chown`

```text
-rwxr-x--- 1 alice devs  file
 │└┬┘└┬┘└┬┘
 │ │  │  └── others: ---  = 0
 │ │  └───── group:  r-x  = 5   (r=4, w=2, x=1)
 │ └──────── owner:  rwx  = 7
 └────────── type: - file, d directory, l link
```

```bash
ls -l file; ls -ld folder
chmod 640 file                        # rw- r-- ---
chmod u+x script.sh                   # add execute for owner
chmod -R g+rX folder                  # X = execute only on folders
sudo chown alice:devs file
sudo chown -R www-data:www-data /var/www/site
namei -l /var/www/html/index.html     # permissions of every folder in the path
stat -c '%a %U %G %n' file            # mode owner group name
umask                                 # default permission mask
```

For a folder: **r** = list names, **x** = enter / open files inside, **w** = create and delete files.

## sudo

```bash
sudo -l                               # what am I allowed to run?
sudo -i                               # root shell (use sparingly)
sudo -u www-data ls /var/www/html     # run as another user
sudo visudo                           # edit sudoers safely (syntax check)
sudo visudo -f /etc/sudoers.d/ops     # drop-in file
```

## Packages – `apt`

```bash
sudo apt update                       # refresh package lists
apt list --upgradable
sudo apt upgrade                      # upgrade installed packages
sudo apt full-upgrade                 # also allows adding/removing packages (kernels)
sudo apt install nginx
sudo apt remove nginx                 # keep config
sudo apt purge nginx                  # remove config too
sudo apt autoremove
apt show nginx; apt policy nginx      # info, installed and candidate version
dpkg -l | grep nginx
cat /var/run/reboot-required          # exists if a reboot is needed
```

## SSH – `ssh-keygen`

```bash
ssh-keygen -t ed25519 -C "ulas@ops-lnx01"   # create key pair in ~/.ssh
ssh-copy-id user@host                        # install public key on server
ssh -v user@host                             # verbose, shows why login fails
ssh-keygen -lf ~/.ssh/id_ed25519.pub         # fingerprint
ssh-keygen -R host                           # remove old host key from known_hosts
sudo sshd -t                                 # test sshd config before reload
sudo systemctl reload ssh
```

Required permissions: `~/.ssh` = 700, `~/.ssh/authorized_keys` = 600, home not writable by group/others.

## Scheduled jobs – `cron`

```text
┌─ minute (0-59)
│ ┌─ hour (0-23)
│ │ ┌─ day of month (1-31)
│ │ │ ┌─ month (1-12)
│ │ │ │ ┌─ day of week (0-7, 0 and 7 = Sunday)
│ │ │ │ │
* * * * *  command
30 2 * * * /usr/local/bin/backup.sh    # every day at 02:30
*/5 * * * * /usr/local/bin/check.sh    # every 5 minutes
```

```bash
crontab -l                    # my jobs
crontab -e                    # edit my jobs
sudo crontab -l -u labuser    # another user's jobs
ls /etc/cron.d/               # system jobs (have an extra USER field)
journalctl -t CRON --since "1 hour ago"
grep CRON /var/log/syslog
systemctl list-timers         # systemd timers (the modern alternative)
```

## Disk – `df`, `du`

```bash
df -h                          # free space per filesystem
df -i                          # free inodes (can run out even if space is free)
sudo du -xh --max-depth=1 /var | sort -h       # biggest folders, stay on one filesystem (-x)
sudo find /var -xdev -type f -size +100M -exec ls -lh {} +
sudo lsof +L1                  # deleted files still held open (space not freed yet)
lsblk                          # disks and partitions
sudo journalctl --vacuum-size=200M   # shrink the journal safely
```

## Memory and processes – `top`, `free`

```bash
free -h                        # "available" is the number that matters
uptime                         # load average for 1, 5, 15 min
nproc                          # CPU cores (compare with load average)
top                            # P = sort by CPU, M = by memory, k = kill, q = quit
htop
ps aux --sort=-%cpu | head
ps -eo pid,ppid,user,pcpu,pmem,etime,args --sort=-pcpu | head
pgrep -a nginx
kill PID                       # SIGTERM, ask nicely
kill -9 PID                    # SIGKILL, last resort
renice +10 -p PID              # lower priority
```

## Network – `ss`, `ip`, `dig`

```bash
ip -br addr                    # addresses, short format
ip route                       # routing table, default gateway
ip -br link                    # interfaces up/down
ping -c 3 192.168.100.10
ss -tlnp                       # listening TCP ports and which process (needs sudo for -p)
ss -tnp state established
curl -I http://localhost       # HTTP headers only
dig dc01.lab.local             # full answer
dig +short ubuntu.com
dig @192.168.100.10 lab.local SOA   # ask a specific server
resolvectl status              # which DNS server each interface uses
ls -l /etc/resolv.conf         # should be a symlink to the systemd-resolved stub
cat /etc/hosts
sudo ufw status verbose        # firewall
```

## Quick triage order (any "server is broken" ticket)

1. `uptime` – how long up, load
2. `df -h` and `df -i` – disk
3. `free -h` – memory
4. `systemctl --failed` – failed services
5. `journalctl -p err -b --no-pager | tail -50` – recent errors
6. `ss -tlnp` – is the service listening
7. `ip -br addr`, `ip route`, `dig` – network and DNS

## My notes

TODO: add my own notes here while practising.
