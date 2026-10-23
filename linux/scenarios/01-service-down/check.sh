#!/usr/bin/env bash
# Scenario 01 - check (read-only): is nginx running, enabled and answering?
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

failures=0

# 1. Is the service running right now?
if systemctl is-active --quiet nginx; then
    ok "nginx is running"
else
    fail "nginx is not running"; failures=$((failures + 1))
fi

# 2. Will it start after a reboot?
if systemctl is-enabled --quiet nginx; then
    ok "nginx is enabled at boot"
else
    fail "nginx is not enabled at boot"; failures=$((failures + 1))
fi

# 3. Does the web server answer with HTTP 200? (-s silent, -o discard body, -w print status code)
code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://localhost/ || true)"
if [[ "${code}" == "200" ]]; then
    ok "http://localhost/ answers 200"
else
    fail "http://localhost/ answers '${code}'"; failures=$((failures + 1))
fi

# Exit code 0 = healthy, 1 = something is wrong (useful for automation).
[[ "${failures}" -eq 0 ]]
