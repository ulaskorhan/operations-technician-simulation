#!/usr/bin/env bash
# Scenario 02 - restore: remove the large file and its folder.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

FILL_DIR="/var/log/lab-app"
FILL_FILE="${FILL_DIR}/debug.log"

require_root
require_lab_host

# -f: no error if the file is already gone (for example if I deleted it during the exercise).
rm -f "${FILL_FILE}"
# rmdir only removes an EMPTY folder, so nothing else can be deleted by mistake.
rmdir "${FILL_DIR}" 2>/dev/null || true

df -h /var
