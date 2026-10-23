#!/usr/bin/env bash
# Scenario 06 - check (read-only): are labuser's SSH files safe enough for sshd, and does key login work?
# Run with sudo from your admin account; the login test uses your own key (lab-setup step 6).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

TARGET_USER="${LAB_SSH_USER:-labuser}"
HOME_DIR="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
failures=0

# A file or folder is unsafe for sshd if group or others can write to it.
# find -perm /022 matches if the group-write OR other-write bit is set.
for path in "${HOME_DIR}" "${HOME_DIR}/.ssh" "${HOME_DIR}/.ssh/authorized_keys"; do
    if [[ -n "$(find "${path}" -maxdepth 0 -perm /022 2>/dev/null)" ]]; then
        fail "${path} is writable by group or others ($(stat -c '%a %U' "${path}"))"; failures=$((failures + 1))
    else
        ok "${path} permissions ok ($(stat -c '%a %U' "${path}"))"
    fi
done

# Try a real key login as the test user. BatchMode=yes means "never ask for a password".
if [[ -n "${SUDO_USER:-}" ]]; then
    if sudo -u "${SUDO_USER}" ssh -o BatchMode=yes -o ConnectTimeout=5 \
        -o StrictHostKeyChecking=accept-new "${TARGET_USER}@localhost" true 2>/dev/null; then
        ok "SSH key login as ${TARGET_USER}@localhost works"
    else
        fail "SSH key login as ${TARGET_USER}@localhost failed"; failures=$((failures + 1))
    fi
fi

[[ "${failures}" -eq 0 ]]
