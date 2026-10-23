#!/usr/bin/env bash
# Scenario 03 - restore: put back the original site config, test it, restart nginx.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

SITE_CONF="/etc/nginx/sites-available/default"
BACKUP="${STATE_DIR}/03-nginx-default.bak"

require_root
require_lab_host

if [[ -f "${BACKUP}" ]]; then
    cp -p "${BACKUP}" "${SITE_CONF}"
    rm -f "${BACKUP}"
    echo "Original ${SITE_CONF} restored from backup."
else
    echo "No backup found; leaving ${SITE_CONF} as it is."
fi

# Always test the config before (re)starting. If the test fails, set -e stops the script here.
nginx -t
systemctl restart nginx
echo "nginx is now: $(systemctl is-active nginx)"
