#!/usr/bin/env bash
# Scenario 07 - check (read-only): is the load average reasonable for the number of CPU cores?
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

cores="$(nproc)"
# /proc/loadavg starts with the 1, 5 and 15 minute load averages, for example "0.12 0.20 0.18 ..."
read -r load1 _ _ _ < /proc/loadavg

# Bash cannot compare decimals, so awk does the comparison. Rule of thumb: load above cores = overloaded.
if awk -v l="${load1}" -v c="${cores}" 'BEGIN { exit !(l < c) }'; then
    ok "1-minute load ${load1} is below ${cores} core(s)"
    result=0
else
    fail "1-minute load ${load1} is at or above ${cores} core(s)"
    result=1
fi

echo "Top 5 processes by CPU:"
ps -eo pid,ppid,user,pcpu,etime,args --sort=-pcpu | head -6

exit "${result}"
