#!/usr/bin/env bash
# Scenario 06 - SSH access: make labuser's .ssh folder and authorized_keys world-writable.
# sshd's "StrictModes" refuses keys in files that other users could change, so key login stops working.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

# The test user. Can be changed with: sudo LAB_SSH_USER=otheruser ./break.sh
TARGET_USER="${LAB_SSH_USER:-labuser}"
STATE_FILE="${STATE_DIR}/06-ssh-perms.txt"

require_root
require_lab_host

# Never break the account I am logged in with, or I could lock myself out.
[[ "${TARGET_USER}" == "${SUDO_USER:-}" ]] && die "Refusing to break your own account (${TARGET_USER})."
id "${TARGET_USER}" >/dev/null 2>&1 || die "User ${TARGET_USER} does not exist (see docs/lab-setup.md step 6)."

HOME_DIR="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
SSH_DIR="${HOME_DIR}/.ssh"
KEYS_FILE="${SSH_DIR}/authorized_keys"

[[ -f "${KEYS_FILE}" ]] || die "${KEYS_FILE} does not exist (see docs/lab-setup.md step 6)."
[[ -e "${STATE_FILE}" ]] && die "Saved state already exists, so the fault is probably active. Run sudo ./restore.sh first."

confirm "This will make ${SSH_DIR} and ${KEYS_FILE} world-writable. ${TARGET_USER} will lose SSH key login."

prepare_state_dir
# Save "mode owner group path" for both, so restore.sh can put them back exactly.
stat -c '%a %U %G %n' "${SSH_DIR}" "${KEYS_FILE}" > "${STATE_FILE}"

chmod 777 "${SSH_DIR}"
chmod 666 "${KEYS_FILE}"

echo "Fault injected. Ticket: 'User ${TARGET_USER} cannot log in to $(hostname) with SSH any more.'"
echo "When you are done, run: sudo ./restore.sh"
