#!/usr/bin/env bash
# Kubernetes scenario 01 - roll out a broken version of the "web" deployment.
#
#   ./break.sh image-tag   # part A: image tag that does not exist  -> ErrImagePull / ImagePullBackOff
#   ./break.sh crashloop   # part B: container starts and exits     -> CrashLoopBackOff
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Reuse the Linux safety functions, but only allow the k3s node.
source "${SCRIPT_DIR}/../../../linux/scenarios/lib/safety.sh"
LAB_HOSTS="ops-lnx02"

require_lab_host

MODE="${1:-}"
case "${MODE}" in
    image-tag) MANIFEST="${SCRIPT_DIR}/broken-image-tag.yaml" ;;
    crashloop) MANIFEST="${SCRIPT_DIR}/broken-crashloop.yaml" ;;
    *) die "usage: $0 image-tag|crashloop" ;;
esac

# The healthy deployment must be there first (kubernetes/README.md step 2).
kubectl -n ops-lab get deployment web >/dev/null 2>&1 \
    || die "deployment ops-lab/web not found. Deploy it first (kubernetes/README.md step 2)."

confirm "This will roll out a broken version (${MODE}) of deployment ops-lab/web."

kubectl apply -f "${MANIFEST}"

echo "Fault injected. Ticket: 'The deployment of the new web version on $(hostname) never finishes.'"
echo "When you are done, run: ./restore.sh"
