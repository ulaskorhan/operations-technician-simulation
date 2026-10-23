#!/usr/bin/env bash
# Scenario 03 - config error: remove a semicolon from the nginx site config, then restart.
# This copies a classic typo during a change. The restart fails and the site goes down.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

SITE_CONF="/etc/nginx/sites-available/default"
BACKUP="${STATE_DIR}/03-nginx-default.bak"

require_root
require_lab_host

[[ -f "${SITE_CONF}" ]] || die "${SITE_CONF} not found. Is nginx installed?"
[[ -e "${BACKUP}" ]] && die "A backup already exists, so the fault is probably active. Run sudo ./restore.sh first."
nginx -t 2>/dev/null || die "nginx config is already broken. Fix it or run restore.sh first."

confirm "This will put a syntax error in ${SITE_CONF} and restart nginx (the site will go down)."

prepare_state_dir
# -p keeps the original owner, mode and timestamp on the backup copy.
cp -p "${SITE_CONF}" "${BACKUP}"

# sed: on the first line matching 'listen 80 default_server;' remove the ';'.
# "0,/pattern/" means "from the start of the file up to the first match only".
sed -i '0,/listen 80 default_server;/s//listen 80 default_server/' "${SITE_CONF}"

# If the config still passes the test, the line was not found (the file is not the Ubuntu default).
if nginx -t 2>/dev/null; then
    rm -f "${BACKUP}"
    die "Could not find 'listen 80 default_server;' in ${SITE_CONF}. Nothing was changed."
fi

# A restart with a broken config fails. "|| true" lets the script continue so it can print the ticket.
systemctl restart nginx 2>/dev/null || true

echo "Fault injected. Ticket: 'After a colleague's change, the website on $(hostname) is down.'"
echo "When you are done, run: sudo ./restore.sh"
