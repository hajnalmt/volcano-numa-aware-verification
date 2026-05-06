#!/usr/bin/env bash
set -euo pipefail

# Deploy node-scoped resource-exporter installer and collect rollout/log/CR evidence.
#
# Usage:
#   ./scripts/collect-resource-exporter-evidence.sh <node>
#   ./scripts/collect-resource-exporter-evidence.sh lsps044x
#
# Expected installer files:
#   evidence/2026-05-06/installer-numa-topo-lsps044x.yaml
#   evidence/2026-05-06/installer-numa-topo-lsps064x.yaml

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <node>" >&2
  exit 1
fi

NODE="$1"
REPO_DIR="/home/uih20178/Github/volcano-numa-aware-verification"
OUT_DIR="${REPO_DIR}/evidence/2026-05-06"
NS="volcano-system"
DS="resource-exporter-daemonset"
LABEL="name=resource-topology"
INSTALLER="${OUT_DIR}/installer-numa-topo-${NODE}.yaml"
WAIT_SECONDS=120
SLEEP_SECONDS=5
LOG_WAIT_PATTERN='discovered.*gpu|numa='

if [[ ! -f "${INSTALLER}" ]]; then
  echo "Installer not found: ${INSTALLER}" >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"

echo "Applying installer: ${INSTALLER}"
kubectl apply -f "${INSTALLER}" | tee "${OUT_DIR}/apply-${NODE}.txt"

echo "Waiting for rollout..."
kubectl -n "${NS}" rollout status ds/"${DS}" --timeout=300s \
  | tee "${OUT_DIR}/rollout-${NODE}.txt"

echo "Collecting pod inventory..."
kubectl -n "${NS}" get pods -l "${LABEL}" -o wide \
  | tee "${OUT_DIR}/pods-resource-topology-${NODE}.txt"

POD="$(kubectl -n "${NS}" get pod -l "${LABEL}" --field-selector "spec.nodeName=${NODE}" -o jsonpath='{.items[0].metadata.name}')"

if [[ -z "${POD}" ]]; then
  echo "No resource-topology pod found on node ${NODE}" >&2
  exit 1
fi

echo "Collecting daemonset and pod describe output..."
kubectl -n "${NS}" describe ds "${DS}" > "${OUT_DIR}/describe-ds-${NODE}.txt"
kubectl -n "${NS}" describe pod "${POD}" > "${OUT_DIR}/describe-pod-${NODE}.txt"

echo "Waiting for exporter loop activity (${WAIT_SECONDS}s max)..."
elapsed=0
while [[ ${elapsed} -lt ${WAIT_SECONDS} ]]; do
  if timeout 15 kubectl -n "${NS}" logs "${POD}" --tail=300 | grep -Eiq "${LOG_WAIT_PATTERN}"; then
    echo "Detected exporter GPU discovery log pattern."
    break
  fi
  echo "No matching discovery logs yet (${elapsed}s/${WAIT_SECONDS}s), retrying..."
  sleep "${SLEEP_SECONDS}"
  elapsed=$((elapsed + SLEEP_SECONDS))
done
if [[ ${elapsed} -ge ${WAIT_SECONDS} ]]; then
  echo "WARNING: exporter discovery log pattern not observed within timeout" \
    | tee "${OUT_DIR}/warning-no-discovery-log-${NODE}.txt"
fi

echo "Collecting logs from pod: ${POD}"
kubectl -n "${NS}" logs "${POD}" --tail=1000 \
  | tee "${OUT_DIR}/logs-resource-topology-${NODE}.txt"

echo "Waiting for Numatopology entry for ${NODE} (${WAIT_SECONDS}s max)..."
elapsed=0
found=0
while [[ ${elapsed} -lt ${WAIT_SECONDS} ]]; do
  if kubectl get numatopologies -A --no-headers 2>/dev/null | grep -q "${NODE}"; then
    found=1
    break
  fi
  sleep "${SLEEP_SECONDS}"
  elapsed=$((elapsed + SLEEP_SECONDS))
done

echo "Collecting Numatopology CRs..."
kubectl get numatopologies -A | tee "${OUT_DIR}/numatopologies-list-after-${NODE}.txt"
kubectl get numatopologies -A -o yaml > "${OUT_DIR}/numatopologies-after-${NODE}.yaml"

if [[ ${found} -eq 1 ]]; then
  # numatopologies.nodeinfo.volcano.sh is cluster-scoped in this environment,
  # and object names match node names (e.g. lsps044x, lsps064x).
  kubectl get numatopology "${NODE}" -o yaml > "${OUT_DIR}/numatopology-${NODE}.yaml"
else
  echo "WARNING: No Numatopology entry found for ${NODE} within ${WAIT_SECONDS}s" \
    | tee "${OUT_DIR}/warning-no-numatopology-${NODE}.txt"
fi

echo "Done. Evidence written under: ${OUT_DIR}"
