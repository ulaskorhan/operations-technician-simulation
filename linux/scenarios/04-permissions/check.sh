#!/usr/bin/env bash
# Scenario 04 - check (read-only): can nginx's user read the web root, and does the site answer?
# Run with sudo, because "sudo -u www-data" is used to test access as the nginx user.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

WEBROOT="/var/www/html"
failures=0

# To list a folder you need read (r); to open files inside it you need execute (x).
if sudo -u www-data test -r "${WEBROOT}" && sudo -u www-data test -x "${WEBROOT}"; then
    ok "www-data can read and enter ${WEBROOT}"
else
    fail "www-data cannot read or enter ${WEBROOT}"; failures=$((failures + 1))
fi

code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://localhost/ || true)"
if [[ "${code}" == "200" ]]; then
    ok "http://localhost/ answers 200"
else
    fail "http://localhost/ answers '${code}'"; failures=$((failures + 1))
fi

[[ "${failures}" -eq 0 ]]
