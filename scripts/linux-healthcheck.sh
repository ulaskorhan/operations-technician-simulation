#!/usr/bin/env bash
# linux-healthcheck.sh - simple health check that writes its results to syslog.
#
# Each finding is one syslog line with the tag "ops-healthcheck" in key=value format, for example:
#   ops-healthcheck: status=WARN check=disk mount=/var used_pct=93 threshold=85
# rsyslog writes it to /var/log/syslog, and the Splunk Universal Forwarder sends it to Splunk,
# where key=value pairs become searchable fields automatically.
#
# Usage:   sudo ./linux-healthcheck.sh          (or from cron, see the bottom of this file)
# Options: thresholds can be changed with environment variables, e.g. DISK_WARN=90 ./linux-healthcheck.sh

set -uo pipefail

TAG="ops-healthcheck"
DISK_WARN="${DISK_WARN:-85}"    # percent used
MEM_WARN="${MEM_WARN:-90}"      # percent used
problems=0

# Write one line to syslog and to the screen.
#   $1 = status (OK or WARN), rest = key=value pairs
log() {
    local status="$1"
    shift
    local priority="user.info"
    if [[ "${status}" != "OK" ]]; then
        priority="user.warning"
        problems=$((problems + 1))
    fi
    logger -t "${TAG}" -p "${priority}" "status=${status} $*"
    echo "status=${status} $*"
}

# ---- Disk: every real filesystem (-x skips memory and snap filesystems) ----------
# df -P gives one line per filesystem in a fixed format; NR>1 skips the header.
while read -r used_pct mount; do
    used="${used_pct%\%}"   # remove the % sign
    if [[ "${used}" -ge "${DISK_WARN}" ]]; then
        log WARN "check=disk mount=${mount} used_pct=${used} threshold=${DISK_WARN}"
    else
        log OK "check=disk mount=${mount} used_pct=${used}"
    fi
done < <(df -P -x tmpfs -x devtmpfs -x squashfs -x overlay | awk 'NR>1 {print $5, $6}')

# ---- Memory: used = total - available (from /proc/meminfo, values in kB) -------
mem_total="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"
mem_avail="$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)"
mem_used_pct=$(( (mem_total - mem_avail) * 100 / mem_total ))
if [[ "${mem_used_pct}" -ge "${MEM_WARN}" ]]; then
    log WARN "check=memory used_pct=${mem_used_pct} threshold=${MEM_WARN}"
else
    log OK "check=memory used_pct=${mem_used_pct}"
fi

# ---- Load: compare the 1-minute load average with the number of CPU cores -------
cores="$(nproc)"
read -r load1 _ < /proc/loadavg
# awk is used because bash cannot compare decimal numbers.
if awk -v l="${load1}" -v c="${cores}" 'BEGIN { exit !(l >= c) }'; then
    log WARN "check=load load1=${load1} cores=${cores}"
else
    log OK "check=load load1=${load1} cores=${cores}"
fi

# ---- Failed systemd units ---------------------------------------------------------
failed_units="$(systemctl --failed --plain --no-legend | awk '{print $1}')"
if [[ -n "${failed_units}" ]]; then
    for unit in ${failed_units}; do
        log WARN "check=service unit=${unit} state=failed"
    done
else
    log OK "check=service failed_units=0"
fi

# ---- Summary line (easy to search for in Splunk) ------------------------------------
logger -t "${TAG}" -p user.info "status=SUMMARY problems=${problems} host=$(hostname -s)"
echo "Done: ${problems} problem(s). See: journalctl -t ${TAG} -n 20"

# Exit code 0 = healthy, 1 = at least one warning.
[[ "${problems}" -eq 0 ]]

# To run every 5 minutes, copy the script and add a cron file:
#   sudo install -m 755 linux-healthcheck.sh /usr/local/bin/linux-healthcheck.sh
#   echo '*/5 * * * * root /usr/local/bin/linux-healthcheck.sh >/dev/null 2>&1' | sudo tee /etc/cron.d/ops-healthcheck
