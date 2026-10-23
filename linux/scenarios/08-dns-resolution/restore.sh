#!/usr/bin/env bash
# Scenario 08 - restore: put /etc/resolv.conf back the way it was.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

RESOLV="/etc/resolv.conf"
LINK_STATE="${STATE_DIR}/08-resolv-link.txt"
FILE_BACKUP="${STATE_DIR}/08-resolv.conf.bak"
# Ubuntu's default symlink target (relative to /etc).
DEFAULT_TARGET="../run/systemd/resolve/stub-resolv.conf"

require_root
require_lab_host

if [[ -f "${LINK_STATE}" ]]; then
    target="$(cat "${LINK_STATE}")"
    # ln -sfn: create a symlink (-s), replace what is there (-f), treat an existing link as a file (-n).
    ln -sfn "${target}" "${RESOLV}"
    rm -f "${LINK_STATE}"
    echo "Symlink restored: ${RESOLV} -> ${target}"
elif [[ -f "${FILE_BACKUP}" ]]; then
    rm -f "${RESOLV}"
    cp -p "${FILE_BACKUP}" "${RESOLV}"
    rm -f "${FILE_BACKUP}"
    echo "Original ${RESOLV} file restored."
else
    ln -sfn "${DEFAULT_TARGET}" "${RESOLV}"
    echo "No saved state; ${RESOLV} now points to the Ubuntu default ${DEFAULT_TARGET}"
fi

ls -l "${RESOLV}"
