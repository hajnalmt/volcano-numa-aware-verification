#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/numa-check.sh <node-name> [output-dir]
# Example:
#   ./scripts/numa-check.sh lsps064x /tmp/numa-evidence

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <node-name> [output-dir]" >&2
  exit 1
fi

NODE="$1"
OUT_DIR="${2:-}"

POD="$(kubectl -n gpu-operator get pods \
  --field-selector "spec.nodeName=${NODE}" \
  -o json | jq -r '[.items[] | select(.metadata.name | startswith("nvidia-driver-daemonset-")) | .metadata.name][0] // empty')"

if [[ -z "${POD}" ]]; then
  echo "No nvidia-driver-daemonset pod found on node ${NODE}" >&2
  exit 1
fi

CTR=""
for c in $(kubectl -n gpu-operator get pod "${POD}" -o json | jq -r '.spec.containers[].name'); do
  if kubectl -n gpu-operator exec "${POD}" -c "${c}" -- sh -lc 'command -v nvidia-smi >/dev/null 2>&1'; then
    CTR="${c}"
    break
  fi
done

if [[ -z "${CTR}" ]]; then
  echo "No container with nvidia-smi found in pod ${POD}" >&2
  exit 1
fi

echo "NODE=${NODE} POD=${POD}"
echo "CONTAINER=${CTR}"

if [[ -n "${OUT_DIR}" ]]; then
  mkdir -p "${OUT_DIR}"
  kubectl -n gpu-operator exec "${POD}" -c "${CTR}" -- nvidia-smi -L | tee "${OUT_DIR}/${NODE}-nvidia-smi-L.txt"
  kubectl -n gpu-operator exec "${POD}" -c "${CTR}" -- nvidia-smi topo -m | tee "${OUT_DIR}/${NODE}-nvidia-smi-topo-m.txt"
else
  kubectl -n gpu-operator exec -it "${POD}" -c "${CTR}" -- nvidia-smi -L
  kubectl -n gpu-operator exec -it "${POD}" -c "${CTR}" -- nvidia-smi topo -m
fi
