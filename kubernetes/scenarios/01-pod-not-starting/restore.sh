#!/usr/bin/env bash
# Kubernetes scenario 01 - restore: apply the known good manifest again and wait for the rollout.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../linux/scenarios/lib/safety.sh"
LAB_HOSTS="ops-lnx02"

require_lab_host

# apply compares with what it applied last time, so it also removes the "args" line from part B.
kubectl apply -f "${SCRIPT_DIR}/../../manifests/nginx-deployment.yaml"
kubectl -n ops-lab rollout status deployment/web --timeout=120s
kubectl -n ops-lab get pods -l app=web
