#!/usr/bin/env bash
# Scenario 05 - restore: remove the cron job, the job script and any backups it made.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

JOB_SCRIPT="/usr/local/bin/ops-lab-backup.sh"
CRON_FILE="/etc/cron.d/ops-lab-backup"
DEST_DIR="/srv/backups"

require_root
require_lab_host

# Remove the schedule first, so the job cannot start again while cleaning up.
rm -f "${CRON_FILE}"
rm -f "${JOB_SCRIPT}"

# If my fix created /srv/backups, remove only the archives this job made, then the folder if empty.
if [[ -d "${DEST_DIR}" ]]; then
    rm -f "${DEST_DIR}"/etc-*.tar.gz
    rmdir "${DEST_DIR}" 2>/dev/null || echo "${DEST_DIR} is not empty; left in place."
fi

echo "Scenario 05 cleaned up."
