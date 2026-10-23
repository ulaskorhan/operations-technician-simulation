# Lab setup: OPS-LNX01 and OPS-LNX02

Step-by-step install of the two Ubuntu Server 24.04 LTS machines.
DC01, SPLUNK01 and WS01 already exist and are not covered here.

| Host | IP | Role |
|------|----|------|
| OPS-LNX01 | 192.168.100.40 | Ansible control node, nginx |
| OPS-LNX02 | 192.168.100.41 | Managed node, nginx, k3s |

## 0. Find your subnet

The repo uses `192.168.100` as a placeholder subnet. Find the real one first:

1. In VMware Workstation: **Edit → Virtual Network Editor → VMnet8 (NAT)**. Note the subnet (for example `192.168.159.0`).
2. Click **NAT Settings** and note the gateway (usually `.2`).
3. On DC01, run `ipconfig` and check that it really is `.10`.

Replace the placeholder everywhere in the repo (run this from the repo root on Linux):

```bash
grep -rl '192\.168\.100\.' . --exclude-dir=.git | xargs sed -i 's/192\.168\.100\./192.168.159./g'
```

> TODO: my real subnet is `__________` and my gateway is `__________`.

## 1. Create the VMs

For each server, in VMware Workstation:

| Setting | OPS-LNX01 | OPS-LNX02 |
|---------|-----------|-----------|
| ISO | `ubuntu-24.04.x-live-server-amd64.iso` | same |
| CPU | 2 vCPU | 2 vCPU |
| RAM | 2 GB | 4 GB (k3s needs at least 2 GB free) |
| Disk | 25 GB | 30 GB |
| Network | NAT (VMnet8) | NAT (VMnet8) |

Installer choices:

- Language/keyboard: as you prefer (Norwegian keyboard if needed).
- Network: leave on DHCP for now (we set a static IP in step 3).
- Storage: **use entire disk**, and **untick "Set up this disk as an LVM group"** only if you want simple partitions. Keep LVM if you want to practise `lvextend` later.
- Profile: your name, server name `ops-lnx01` / `ops-lnx02`, an admin username (I use the same one on both, for example `ulas`).
- **Tick "Install OpenSSH server".**
- Do not install any extra snaps.

## 2. First login and updates

```bash
sudo apt update
sudo apt full-upgrade -y
sudo apt install -y vim curl git dnsutils net-tools htop tree rsyslog
sudo reboot
```

`dnsutils` gives `dig`, `rsyslog` makes sure `/var/log/syslog` and `/var/log/auth.log` exist (Splunk reads them).

## 3. Static IP (netplan)

Find the interface name:

```bash
ip -br link        # usually ens33 on VMware
ls /etc/netplan/   # note the file name, often 50-cloud-init.yaml
```

Disable cloud-init's network handling so it does not overwrite the file:

```bash
echo 'network: {config: disabled}' | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
```

Edit `/etc/netplan/50-cloud-init.yaml` (example for OPS-LNX01, use `.41` on OPS-LNX02):

```yaml
network:
  version: 2
  ethernets:
    ens33:
      dhcp4: false
      addresses:
        - 192.168.100.40/24
      routes:
        - to: default
          via: 192.168.100.2
      nameservers:
        addresses:
          - 192.168.100.10    # DC01 – resolves lab.local
          - 192.168.100.2     # VMware NAT DNS as a fallback
        search:
          - lab.local
```

Apply and test:

```bash
sudo chmod 600 /etc/netplan/50-cloud-init.yaml
sudo netplan try          # press Enter to accept within 120 s, otherwise it rolls back
ip -br addr
ping -c 2 192.168.100.10
dig +short dc01.lab.local
ping -c 2 ubuntu.com
```

## 4. Hostname

```bash
sudo hostnamectl set-hostname ops-lnx01      # ops-lnx02 on the second server
hostnamectl
```

Add both servers to `/etc/hosts` on both machines (so they work even if DNS is broken in scenario 08):

```text
192.168.100.40  ops-lnx01.lab.local  ops-lnx01
192.168.100.41  ops-lnx02.lab.local  ops-lnx02
```

Optional: add A records for both servers in DNS on DC01 (DNS Manager → `lab.local` → New Host).

## 5. SSH keys

On **OPS-LNX01** (the Ansible control node), create a key for your admin user:

```bash
ssh-keygen -t ed25519 -C "ulas@ops-lnx01"
ssh-copy-id ulas@ops-lnx02
ssh ulas@ops-lnx02 hostname     # should print ops-lnx02 without asking for a password
```

From your Windows PC (PowerShell), you can do the same so you can log in to both servers:

```powershell
ssh-keygen -t ed25519
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh ulas@192.168.100.40 "cat >> ~/.ssh/authorized_keys"
```

Once key login works, turn off password login on both servers:

```bash
sudo tee /etc/ssh/sshd_config.d/10-lab-hardening.conf <<'EOF'
PasswordAuthentication no
PermitRootLogin no
EOF
sudo sshd -t && sudo systemctl reload ssh
```

> Keep one SSH session open while you test this, so you cannot lock yourself out.

## 6. Packages needed by the scenarios

On **both** servers:

```bash
sudo apt install -y nginx
systemctl status nginx --no-pager
curl -I http://localhost
```

Create the test user for scenario 06 (it is not your admin account, so you cannot lock yourself out):

```bash
sudo adduser --disabled-password --gecos "" labuser
sudo install -d -m 700 -o labuser -g labuser /home/labuser/.ssh
cat ~/.ssh/id_ed25519.pub | sudo tee /home/labuser/.ssh/authorized_keys
sudo chown labuser:labuser /home/labuser/.ssh/authorized_keys
sudo chmod 600 /home/labuser/.ssh/authorized_keys
ssh labuser@localhost whoami    # should print labuser
```

## 7. Ansible on OPS-LNX01

```bash
sudo apt install -y ansible ansible-lint yamllint shellcheck
ansible --version
```

Clone this repo:

```bash
git clone https://github.com/ulaskorhan/operations-technician-simulation.git
cd operations-technician-simulation/ansible
ansible all -m ansible.builtin.ping
```

## 8. Snapshots

Take a VMware snapshot of both servers now, called **"clean baseline"**.
If a scenario ever goes wrong and the restore script does not help, revert to this snapshot.

## Checklist

- [ ] TODO: OPS-LNX01 installed, static IP, hostname, updates
- [ ] TODO: OPS-LNX02 installed, static IP, hostname, updates
- [ ] TODO: SSH key login works LNX01 → LNX02 and Windows PC → both
- [ ] TODO: password login disabled
- [ ] TODO: nginx answers on both servers
- [ ] TODO: `labuser` can log in with a key
- [ ] TODO: Ansible ping works against both hosts
- [ ] TODO: "clean baseline" snapshot taken
