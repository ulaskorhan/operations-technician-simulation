#!/usr/bin/env bash
# Scenario 01 - restore: enable nginx at boot and start it now.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

require_root
require_lab_host

# "enable --now" does two things: enable at boot, and start immediately.
systemctl enable --now nginx

echo "nginx is now: $(systemctl is-active nginx), at boot: $(systemctl is-enabled nginx)"
