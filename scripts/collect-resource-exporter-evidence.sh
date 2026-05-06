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

echo "Collecting logs from pod: ${POD}"
kubectl -n "${NS}" logs "${POD}" --tail=500 \
  | tee "${OUT_DIR}/logs-resource-topology-${NODE}.txt"

echo "Collecting Numatopology CRs..."
kubectl get numatopologies -A -o yaml > "${OUT_DIR}/numatopologies-after-${NODE}.yaml"
kubectl get numatopologies -A | tee "${OUT_DIR}/numatopologies-list-after-${NODE}.txt"

echo "Done. Evidence written under: ${OUT_DIR}"
