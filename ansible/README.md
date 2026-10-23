# Ansible

Run from **OPS-LNX01** (the control node), always from inside this `ansible/` folder so `ansible.cfg` is used.

```bash
cd ~/operations-technician-simulation/ansible
ansible-inventory --graph          # show groups and hosts
ansible-playbook playbooks/ping.yml
```

Before the first run:

1. Set `remote_user` in [ansible.cfg](ansible.cfg) to your admin user.
2. Fix the IP addresses in [inventory.ini](inventory.ini).
3. SSH once by hand to OPS-LNX02 so its host key is in `known_hosts`.
4. For `users.yml`: add the public keys (see [playbooks/files/keys/README.md](playbooks/files/keys/README.md)).

## Playbooks

| Playbook | Hosts | What it does |
|----------|-------|--------------|
| [ping.yml](playbooks/ping.yml) | linux | Can Ansible log in and run Python on every host? |
| [update.yml](playbooks/update.yml) | linux | `apt update` + full upgrade, autoremove, reboot **only** if `/var/run/reboot-required` exists. One host at a time (`serial: 1`). Never reboots the control node itself. |
| [nginx.yml](playbooks/nginx.yml) | web | Installs nginx, deploys site config and index page from templates, tests with `nginx -t`, reloads nginx through a handler only when the config changed. |
| [users.yml](playbooks/users.yml) | linux | Creates users from [vars/users.yml](playbooks/vars/users.yml) and installs their SSH keys. |
| [healthcheck.yml](playbooks/healthcheck.yml) | linux | Disk, memory, load and failed services; prints a summary and writes `reports/<host>-<date>.txt`. |

`-K` (`--ask-become-pass`) asks for the sudo password. Every playbook that changes something needs it.

## Idempotency

A task is **idempotent** when running it again does not change anything if the system is already in the
wanted state. Ansible modules describe the *end state* ("nginx is installed", "this line is in the file"),
not the steps, so they check first and only act when something is different.

What this looks like in practice:

```text
1st run:  ok=6  changed=3  failed=0     # nginx installed, config written, handler reloaded nginx
2nd run:  ok=6  changed=0  failed=0     # nothing to do: everything is already correct
```

Why it matters in operations:

- I can run the same playbook on 1 or 100 servers without worrying about what state each one is in.
- `changed=0` on a second run is proof that the system matches the code (no drift).
- If someone changes a managed file by hand, the next run shows `changed` and puts it back.

Things that break idempotency, and how the playbooks avoid them:

| Problem | Fix used here |
|---------|---------------|
| `command`/`shell` always reports "changed" | `changed_when: false` for read-only commands (`nginx -t`, `systemctl --failed`) |
| Restarting a service on every run | A **handler** (`notify: Reload nginx`) runs only when the config task changed |
| `apt update` on every run | `cache_valid_time: 3600` |
| Rebooting every time | `when: reboot_required.stat.exists` |

## Run against one host first: `--limit` and `--check`

This is how I would roll out a change on a customer system: test on one server, look at the result, then do the rest.

```bash
# 1. Which hosts would be affected? (no connection, just lists them)
ansible-playbook playbooks/nginx.yml --list-hosts

# 2. Dry run on ONE host: --check changes nothing, --diff shows what would change in files
ansible-playbook playbooks/nginx.yml -K --check --diff --limit ops-lnx02

# 3. Real run on that one host
ansible-playbook playbooks/nginx.yml -K --limit ops-lnx02

# 4. Verify by hand
curl -I http://192.168.100.41/
curl http://192.168.100.41/health

# 5. Run it again on the same host: expect changed=0 (idempotent)
ansible-playbook playbooks/nginx.yml -K --limit ops-lnx02

# 6. Roll out to everything else
ansible-playbook playbooks/nginx.yml -K
```

Notes on `--check`:

- Modules that support check mode report what they *would* do. `command` and `shell` tasks are skipped.
- A later task can fail in check mode because an earlier task did not really run
  (for example "start nginx" when nginx was never installed). That is expected on a brand-new host.

Other useful flags:

| Flag | Use |
|------|-----|
| `--limit ops-lnx02` or `--limit 'web:!ops-lnx01'` | Only these hosts |
| `--start-at-task "Deploy the index page"` | Continue from a task after fixing a problem |
| `--step` | Ask before each task |
| `-v`, `-vvv` | More output, for troubleshooting connection problems |
| `--syntax-check` | Only check the YAML/playbook structure |

## Ad-hoc commands

```bash
ansible linux -m ansible.builtin.command -a "uptime"
ansible linux -m ansible.builtin.command -a "df -h /"
ansible web -b -K -m ansible.builtin.service -a "name=nginx state=restarted"
```

## Lint

```bash
yamllint .
ansible-lint
```

## My results

TODO: after running each playbook, write the 1st and 2nd run recap lines and anything that went wrong in [docs/lab-journal.md](../docs/lab-journal.md).
