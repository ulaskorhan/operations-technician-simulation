#!/usr/bin/env bash
# Scenario 07 - high load: start one CPU-burning process per CPU core.
# The processes run as user "nobody" and stop by themselves after 1 hour (safety net).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/safety.sh"

WORKER="/usr/local/bin/ops-lab-report-gen"
MAX_SECONDS=3600

require_root
require_lab_host

pgrep -f "${WORKER}" >/dev/null && die "Workers are already running. Run sudo ./restore.sh first."

cores="$(nproc)"
confirm "This will start ${cores} CPU-burning process(es) for up to ${MAX_SECONDS} seconds."

# The "runaway" program: an endless loop that does nothing but use CPU.
cat > "${WORKER}" <<'EOF'
#!/usr/bin/env bash
# ops-lab-report-gen - fake report generator with a bug: it never finishes (lab scenario 07).
while :; do :; done
EOF
chmod 755 "${WORKER}"

# Start one worker per core in the background (&).
#   nohup   - keep running if this terminal is closed
#   runuser - run as user "nobody", not root
#   timeout - kill it automatically after MAX_SECONDS
for _ in $(seq "${cores}"); do
    nohup runuser -u nobody -- timeout "${MAX_SECONDS}" "${WORKER}" >/dev/null 2>&1 &
done

echo "Fault injected. Ticket: '$(hostname) is very slow.'"
echo "When you are done, run: sudo ./restore.sh"
