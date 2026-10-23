#!/usr/bin/env bash
# Scenario 04 - permissions: give the web root the wrong owner and mode.
# nginx runs as user www-data. If www-data cannot enter the folder, visitors get "403 Forbidden".
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

WEBROOT="/var/www/html"
STATE_FILE="${STATE_DIR}/04-webroot-perms.txt"

require_root
require_lab_host

[[ -d "${WEBROOT}" ]] || die "${WEBROOT} not found. Is nginx installed?"
[[ -e "${STATE_FILE}" ]] && die "Saved state already exists, so the fault is probably active. Run sudo ./restore.sh first."

confirm "This will change the owner and mode of ${WEBROOT} and its files (the site will show 403)."

prepare_state_dir
# Save mode, owner, group and path of the folder and every file directly inside it.
# Example line: "644 root root /var/www/html/index.nginx-debian.html"
find "${WEBROOT}" -maxdepth 1 -exec stat -c '%a %U %G %n' {} + > "${STATE_FILE}"

# Wrong owner (nobody) and a mode that only the owner can use.
chown -R nobody:nogroup "${WEBROOT}"
chmod 700 "${WEBROOT}"
find "${WEBROOT}" -maxdepth 1 -type f -exec chmod 600 {} +

echo "Fault injected. Ticket: 'The website on $(hostname) shows 403 Forbidden.'"
echo "When you are done, run: sudo ./restore.sh"
