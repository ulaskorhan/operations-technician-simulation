#!/usr/bin/env bash
# Kubernetes scenario 01 - check (read-only): are all web pods up to date and ready?
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../linux/scenarios/lib/safety.sh"

# jsonpath picks single fields out of the deployment's status.
desired="$(kubectl -n ops-lab get deployment web -o jsonpath='{.spec.replicas}')"
updated="$(kubectl -n ops-lab get deployment web -o jsonpath='{.status.updatedReplicas}')"
ready="$(kubectl -n ops-lab get deployment web -o jsonpath='{.status.readyReplicas}')"
unavailable="$(kubectl -n ops-lab get deployment web -o jsonpath='{.status.unavailableReplicas}')"

echo "[INFO] desired=${desired} updated=${updated:-0} ready=${ready:-0} unavailable=${unavailable:-0}"
kubectl -n ops-lab get pods -l app=web

# Healthy = every desired pod runs the newest version, is ready, and nothing is unavailable.
if [[ "${updated:-0}" == "${desired}" && "${ready:-0}" == "${desired}" && -z "${unavailable}" ]]; then
    ok "deployment ops-lab/web is fully rolled out and ready"
else
    fail "deployment ops-lab/web is not healthy"
    exit 1
fi
