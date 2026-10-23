#!/usr/bin/env bash
# Scenario 07 - restore: stop all worker processes and remove the worker program.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

WORKER="/usr/local/bin/ops-lab-report-gen"

require_root
require_lab_host

# pkill -f matches the full command line, so it finds both the worker and its "timeout" parent.
# It sends SIGTERM (polite stop) first.
pkill -f "${WORKER}" || echo "No workers were running."

sleep 1
# Anything still alive gets SIGKILL (cannot be ignored).
pkill -9 -f "${WORKER}" 2>/dev/null || true

rm -f "${WORKER}"
uptime
