# Monitoring – Splunk Universal Forwarder on the Linux servers

SPLUNK01 already receives Windows logs on TCP 9997 (`wineventlog`, `sysmon`).
This adds `/var/log/syslog` and `/var/log/auth.log` from OPS-LNX01 and OPS-LNX02 into a new `linux` index.

## 1. On SPLUNK01: create the index

**Settings → Indexes → New Index** → Index name `linux` → Save.

Check that receiving is on: **Settings → Forwarding and receiving → Configure receiving** shows port 9997.

If Windows Firewall blocks it, allow the port (PowerShell as admin):

```powershell
New-NetFirewallRule -DisplayName 'Splunk receiving 9997' -Direction Inbound -Protocol TCP -LocalPort 9997 -Action Allow
```

## 2. On each Linux server: install the Universal Forwarder

Download the **Universal Forwarder** `.deb` for Linux x86_64 from splunk.com (free account needed)
and copy it to the server (for example with `scp`).

```bash
sudo dpkg -i splunkforwarder-*-linux-amd64.deb

# Start at boot as the splunkfwd user (created by the package). Asks for a new admin user/password.
sudo /opt/splunkforwarder/bin/splunk enable boot-start -systemd-managed 1 -user splunkfwd --accept-license

# syslog and auth.log belong to group adm; the forwarder needs to be in that group to read them.
sudo usermod -aG adm splunkfwd
```

## 3. Install the config from this repo

```bash
APP=/opt/splunkforwarder/etc/apps/ops_lab_inputs/local
sudo mkdir -p "$APP"
sudo cp monitoring/splunk-uf/inputs.conf monitoring/splunk-uf/outputs.conf "$APP"/
sudo chown -R splunkfwd:splunkfwd /opt/splunkforwarder/etc/apps/ops_lab_inputs
sudo systemctl restart SplunkForwarder
```

## 4. Verify

On the Linux server:

```bash
sudo systemctl status SplunkForwarder --no-pager
sudo /opt/splunkforwarder/bin/splunk list forward-server      # should show 192.168.100.20:9997 as active
sudo /opt/splunkforwarder/bin/splunk list monitor             # should list syslog and auth.log
sudo tail -n 50 /opt/splunkforwarder/var/log/splunk/splunkd.log | grep -iE 'error|warn|connect'
logger -t ops-test "hello from $(hostname)"
```

In Splunk on SPLUNK01:

```spl
index=linux ops-test
```

```spl
index=linux | stats count by host, sourcetype
```

## 5. Send the health check to Splunk

[scripts/linux-healthcheck.sh](../scripts/linux-healthcheck.sh) writes `key=value` lines to syslog with the tag
`ops-healthcheck`. Once it runs from cron (see the end of the script), its results show up in `index=linux`.

## Saved searches and alerts

See [saved-searches.md](saved-searches.md).

## My results

TODO: write the UF version I installed, any problems (permissions, firewall, port), and the first events I saw.
