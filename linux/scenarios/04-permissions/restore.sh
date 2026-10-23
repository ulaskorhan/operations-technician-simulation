#!/usr/bin/env bash
# Scenario 04 - restore: put back the owner and mode saved by break.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

WEBROOT="/var/www/html"
STATE_FILE="${STATE_DIR}/04-webroot-perms.txt"

require_root
require_lab_host

if [[ -f "${STATE_FILE}" ]]; then
    # Read one line at a time. The last variable (path) gets the rest of the line,
    # so paths with spaces still work.
    while read -r mode owner group path; do
        chown "${owner}:${group}" "${path}"
        chmod "${mode}" "${path}"
    done < "${STATE_FILE}"
    rm -f "${STATE_FILE}"
    echo "Saved permissions restored."
else
    # No saved state: use the Ubuntu defaults (root owns it, everyone can read).
    echo "No saved state; applying default owner root:root, folder 755, files 644."
    chown -R root:root "${WEBROOT}"
    chmod 755 "${WEBROOT}"
    find "${WEBROOT}" -maxdepth 1 -type f -exec chmod 644 {} +
fi

ls -ld "${WEBROOT}"
ls -l "${WEBROOT}"
