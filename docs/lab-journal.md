# Lab journal

A dated log of what I did, what I found and what I learned.
One entry per exercise. Copy the template below for each new entry, newest at the bottom.

Write it like a shift handover: short, factual, and with the real commands I ran.

---

## Template

### YYYY-MM-DD – Exercise name

- **Host(s):**
- **Time spent:**
- **Goal:** what I wanted to practise
- **What I did:** the main steps, in order
- **Commands that helped most:**
  ```bash
  # paste the real commands here
  ```
- **What went wrong / what surprised me:**
- **What I learned:**
- **How this maps to the Operations Technician role:**
- **Follow-up:** anything I want to try again or read more about
- **Links:** runbook, incident report or change request for this exercise

---

## Entries

### TODO – Lab setup (OPS-LNX01 and OPS-LNX02)

- **Host(s):** OPS-LNX01, OPS-LNX02
- **Time spent:** TODO
- **Goal:** TODO
- **What I did:** TODO
- **Commands that helped most:** TODO
- **What went wrong / what surprised me:** TODO
- **What I learned:** TODO
- **How this maps to the Operations Technician role:** TODO
- **Follow-up:** TODO
- **Links:** [docs/lab-setup.md](lab-setup.md)

### 2026-11-21 – Network commands and a real DNS fault in the Windows lab

- **Host(s):** Mac (home network), Windows VMs in VMware Workstation
- **Goal:** practise `ping`, `nslookup` and `tracert` on each OS
- **What I did:** ran the commands from [networking/practice-log.md](../networking/practice-log.md) on the
  Mac, then on the Windows VM. `nslookup dc01.lab.local` and the `_ldap._tcp.dc._msdcs.lab.local` SRV
  lookup returned "Non-existent domain"; `ping 192.168.182.10` and `nslookup ... 192.168.182.10` got no
  answer. `ipconfig /all` on the server VM showed a random host name (`WIN-2ME75DLT49A`), DHCP enabled,
  address `192.168.182.147`, an empty primary DNS suffix and VMware's `192.168.182.2` as DNS server.
- **What went wrong / what surprised me:** the lab subnet is `192.168.182`, not the `192.168.100`
  placeholder, and the server had never been renamed or promoted to a domain controller, so `lab.local`
  did not exist. The client asked VMware's DNS instead of a DC.
- **Follow-up:** build DC01 with [docs/windows-lab-setup.md](windows-lab-setup.md).

### 2026-11-22 – Linux scenarios 01 and 02

- **Host(s):** ops-lnx01 (Ubuntu 24.04 in Multipass on my Mac, because the VMware VMs were too slow on
  my laptop)
- **What I did:** scenario 01 (nginx stopped and disabled) and scenario 02 (`/var` 97% full).
- **Links:** [runbook 01](../linux/scenarios/01-service-down/runbook.md),
  [runbook 02](../linux/scenarios/02-disk-full/runbook.md)

### 2026-11-23 – Scenario 03, Ansible nginx playbook, failed-login search

- **Host(s):** ops-lnx01 (Multipass)
- **Scenario 03:** `nginx -t` pointed at line 23, the missing `;` was on line 22.
  See [runbook 03](../linux/scenarios/03-config-error/runbook.md).
- **Installing Ansible failed first:** apt was broken by a kernel update that stopped halfway while the
  disk was full in scenario 02. Fixed with `sudo apt --fix-broken install -y`, then
  `sudo apt install -y ansible`. Details in [runbook 02](../linux/scenarios/02-disk-full/runbook.md).
- **Ansible, dry run first** (`ansible-playbook playbooks/nginx.yml --limit ops-lnx01 --check --diff`):
  the diff showed the new index page from `index.html.j2` (13 lines added), the `nginx -t` task was
  `skipping` (command tasks do not run in check mode) and the "Reload nginx" handler was notified.

  ```text
  ops-lnx01                  : ok=6    changed=3    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
  ```

- **Ansible, run again after the real run** (`ansible-playbook playbooks/nginx.yml --limit ops-lnx01`):
  every task `ok`, the config test ran, no handler ran.

  ```text
  ops-lnx01                  : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
  ```

  `changed=0` on the repeat run is idempotency: the server already matched the playbook, so nothing was
  changed and nginx was not reloaded.
- **Failed-login search:** practised the logic of Splunk search 1 with grep on auth.log. See
  [monitoring/saved-searches.md](../monitoring/saved-searches.md#my-results).
- **What I learned:** TODO: in my own words.
