#!/usr/bin/env bash
# Scenario 08 - DNS resolution: replace /etc/resolv.conf with a file pointing at a dead DNS server.
#
# On Ubuntu 24.04, /etc/resolv.conf is normally a symlink to systemd-resolved's stub file
# (nameserver 127.0.0.53). Here it becomes a plain file pointing at 192.0.2.53, an address
# reserved for documentation (RFC 5737) that never answers.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

RESOLV="/etc/resolv.conf"
LINK_STATE="${STATE_DIR}/08-resolv-link.txt"
FILE_BACKUP="${STATE_DIR}/08-resolv.conf.bak"

require_root
require_lab_host

if [[ -e "${LINK_STATE}" || -e "${FILE_BACKUP}" ]]; then
    die "Saved state already exists, so the fault is probably active. Run sudo ./restore.sh first."
fi

confirm "This will replace ${RESOLV} with a wrong DNS server. Name lookups will stop working."

prepare_state_dir
# Save what was there: the symlink target if it is a symlink (-L), otherwise a copy of the file.
if [[ -L "${RESOLV}" ]]; then
    readlink "${RESOLV}" > "${LINK_STATE}"
else
    cp -p "${RESOLV}" "${FILE_BACKUP}"
fi

# Remove the symlink/file and write a plain file in its place.
rm -f "${RESOLV}"
cat > "${RESOLV}" <<'EOF'
# Edited by hand during "DNS migration" (lab scenario 08)
nameserver 192.0.2.53
search lab.local
EOF

echo "Fault injected. Ticket: '$(hostname) cannot reach anything by name (apt update fails too).'"
echo "When you are done, run: sudo ./restore.sh"
