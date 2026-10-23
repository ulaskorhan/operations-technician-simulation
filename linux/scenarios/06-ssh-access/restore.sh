#!/usr/bin/env bash
# Scenario 06 - restore: put back the saved permissions on .ssh and authorized_keys.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

TARGET_USER="${LAB_SSH_USER:-labuser}"
STATE_FILE="${STATE_DIR}/06-ssh-perms.txt"

require_root
require_lab_host

if [[ -f "${STATE_FILE}" ]]; then
    while read -r mode owner group path; do
        chown "${owner}:${group}" "${path}"
        chmod "${mode}" "${path}"
    done < "${STATE_FILE}"
    rm -f "${STATE_FILE}"
    echo "Saved permissions restored."
else
    # No saved state: apply the permissions sshd expects.
    HOME_DIR="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
    echo "No saved state; applying standard permissions (700 on .ssh, 600 on authorized_keys)."
    chown "${TARGET_USER}:${TARGET_USER}" "${HOME_DIR}/.ssh" "${HOME_DIR}/.ssh/authorized_keys"
    chmod 700 "${HOME_DIR}/.ssh"
    chmod 600 "${HOME_DIR}/.ssh/authorized_keys"
fi
