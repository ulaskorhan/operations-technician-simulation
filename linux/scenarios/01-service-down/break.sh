#!/usr/bin/env bash
# Scenario 01 - service down: stop AND disable nginx.
# Stopped = not running now. Disabled = will not start again after a reboot.
set -euo pipefail

# Find the folder this script lives in, then load the shared safety functions.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

require_root
require_lab_host

# nginx must be installed, otherwise there is nothing to break.
command -v nginx >/dev/null || die "nginx is not installed (sudo apt install nginx)."

confirm "This will STOP and DISABLE nginx on $(hostname)."

systemctl stop nginx
systemctl disable nginx

echo "Fault injected. Ticket: 'The website on $(hostname) is down.'"
echo "When you are done, run: sudo ./restore.sh"
