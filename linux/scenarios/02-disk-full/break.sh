#!/usr/bin/env bash
# Scenario 02 - disk full: create one large file under /var/log until /var is ~97% used.
# fallocate reserves the space instantly without writing data, so it is fast.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

FILL_DIR="/var/log/lab-app"
FILL_FILE="${FILL_DIR}/debug.log"

require_root
require_lab_host

[[ -e "${FILL_FILE}" ]] && die "${FILL_FILE} already exists. Run sudo ./restore.sh first."

# df --output=... prints a header line, so tail -1 takes the number; tr removes spaces.
size_kb="$(df --output=size -k /var | tail -1 | tr -d ' ')"
avail_kb="$(df --output=avail -k /var | tail -1 | tr -d ' ')"

# Always leave some space free so the system keeps working:
# 3% of the filesystem, but never less than 300 MB.
keep_kb=$((size_kb * 3 / 100))
min_keep_kb=$((300 * 1024))
if [[ "${keep_kb}" -lt "${min_keep_kb}" ]]; then
    keep_kb="${min_keep_kb}"
fi

fill_kb=$((avail_kb - keep_kb))
[[ "${fill_kb}" -le 0 ]] && die "/var already has less than $((keep_kb / 1024)) MB free. Nothing to do."

confirm "This will create a $((fill_kb / 1024)) MB file in ${FILL_DIR} and fill /var to ~97%."

mkdir -p "${FILL_DIR}"
fallocate -l "${fill_kb}K" "${FILL_FILE}"

echo "Fault injected. Ticket: 'Monitoring alert: /var on $(hostname) is almost full.'"
echo "When you are done, run: sudo ./restore.sh"
