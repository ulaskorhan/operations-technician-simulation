#!/usr/bin/env bash
# Scenario 03 - check (read-only): is the nginx config valid and the site up?
# Run with sudo: nginx -t needs to read files only root can read.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

failures=0

# nginx -t tests the config without changing anything. -q only prints errors.
if nginx -t -q 2>/dev/null; then
    ok "nginx config syntax is valid"
else
    fail "nginx config has errors (run: sudo nginx -t)"; failures=$((failures + 1))
fi

if systemctl is-active --quiet nginx; then
    ok "nginx is running"
else
    fail "nginx is not running"; failures=$((failures + 1))
fi

code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://localhost/ || true)"
if [[ "${code}" == "200" ]]; then
    ok "http://localhost/ answers 200"
else
    fail "http://localhost/ answers '${code}'"; failures=$((failures + 1))
fi

[[ "${failures}" -eq 0 ]]
