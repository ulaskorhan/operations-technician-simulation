#!/usr/bin/env bash
# Scenario 05 - cron failing: install a "backup" job that runs every minute and fails.
# The job writes its error to syslog with logger, so it can be found in the logs (and in Splunk).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

JOB_SCRIPT="/usr/local/bin/ops-lab-backup.sh"
CRON_FILE="/etc/cron.d/ops-lab-backup"
DEST_DIR="/srv/backups"

require_root
require_lab_host

[[ -e "${CRON_FILE}" ]] && die "${CRON_FILE} already exists. Run sudo ./restore.sh first."
[[ -e "${DEST_DIR}" ]] && die "${DEST_DIR} already exists; this scenario needs it to be missing."

confirm "This will install a failing backup job in ${CRON_FILE} that runs every minute."

# The job script. 'EOF' in quotes means nothing inside is expanded now; it is written as-is.
cat > "${JOB_SCRIPT}" <<'EOF'
#!/usr/bin/env bash
# ops-lab-backup.sh - backs up a few files from /etc to /srv/backups (lab scenario 05).
DEST="/srv/backups"
ARCHIVE="${DEST}/etc-$(date +%F-%H%M).tar.gz"

# Run tar and keep its error message (2>&1 sends errors to the same place as normal output).
if output="$(tar -czf "${ARCHIVE}" /etc/hostname /etc/hosts 2>&1)"; then
    logger -t ops-lab-backup "OK: wrote ${ARCHIVE}"
else
    logger -p user.err -t ops-lab-backup "ERROR: backup failed: ${output}"
    exit 1
fi
EOF
chmod 755 "${JOB_SCRIPT}"

# Files in /etc/cron.d have an extra field: the user to run as (here: root).
# Fields: minute hour day-of-month month day-of-week user command
cat > "${CRON_FILE}" <<EOF
# Lab scenario 05 - backup job (installed by break.sh)
* * * * * root ${JOB_SCRIPT}
EOF
chmod 644 "${CRON_FILE}"

echo "Fault injected. Ticket: 'The backup job on $(hostname) is not producing any files.'"
echo "Wait 1-2 minutes before you start, so the job has run."
echo "When you are done, run: sudo ./restore.sh"
