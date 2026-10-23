#!/usr/bin/env bash
# Scenario 05 - check (read-only): did the backup job run successfully in the last few minutes?
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

CRON_FILE="/etc/cron.d/ops-lab-backup"
DEST_DIR="/srv/backups"

if [[ ! -f "${CRON_FILE}" ]]; then
    ok "backup job is not installed (scenario not active)"
    exit 0
fi

failures=0

# Last message the job wrote to the journal. -t = tag, -n 1 = last line, -o cat = message only.
last="$(journalctl -t ops-lab-backup -n 1 --no-pager -o cat 2>/dev/null)"
if [[ "${last}" == OK:* ]]; then
    ok "last job run: ${last}"
else
    fail "last job run: ${last:-no log entry yet}"; failures=$((failures + 1))
fi

# Is there a backup file newer than 5 minutes? (-mmin -5 = modified less than 5 minutes ago)
if [[ -d "${DEST_DIR}" ]] && [[ -n "$(find "${DEST_DIR}" -name 'etc-*.tar.gz' -mmin -5 2>/dev/null)" ]]; then
    ok "recent backup file found in ${DEST_DIR}"
else
    fail "no backup file from the last 5 minutes in ${DEST_DIR}"; failures=$((failures + 1))
fi

[[ "${failures}" -eq 0 ]]
