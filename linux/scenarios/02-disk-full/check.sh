#!/usr/bin/env bash
# Scenario 02 - check (read-only): is /var below the warning threshold?
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

THRESHOLD=90   # percent used that counts as a problem

# pcent looks like " 42%"; tr removes the space and the % sign.
used="$(df --output=pcent /var | tail -1 | tr -d ' %')"

if [[ "${used}" -lt "${THRESHOLD}" ]]; then
    ok "/var is ${used}% used (threshold ${THRESHOLD}%)"
else
    fail "/var is ${used}% used (threshold ${THRESHOLD}%)"
    exit 1
fi

# Files deleted while still open by a process keep using space until the process closes them.
# lsof +L1 lists such files. It only needs to print something if there are any.
if command -v lsof >/dev/null && [[ -n "$(lsof +L1 2>/dev/null | tail -n +2)" ]]; then
    echo "[INFO] Some deleted files are still open (lsof +L1). They still use disk space."
fi
