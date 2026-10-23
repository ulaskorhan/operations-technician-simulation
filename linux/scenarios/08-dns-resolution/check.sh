#!/usr/bin/env bash
# Scenario 08 - check (read-only): can this server resolve internal and external names?
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

failures=0

# Show how resolv.conf is set up. "->" in the output means it is a symlink.
echo "[INFO] $(ls -l /etc/resolv.conf)"

# dig +short prints only the answer. +time/+tries keep the test fast when DNS is broken.
# Note: dig asks the DNS server directly and ignores /etc/hosts. ping uses /etc/hosts first.
for name in dc01.lab.local ubuntu.com; do
    answer="$(dig +short +time=2 +tries=1 "${name}" 2>/dev/null | head -1)"
    # dig prints error lines starting with ";;" when no server answers.
    if [[ -n "${answer}" && "${answer}" != ";"* ]]; then
        ok "${name} resolves to ${answer}"
    else
        fail "${name} does not resolve"; failures=$((failures + 1))
    fi
done

[[ "${failures}" -eq 0 ]]
