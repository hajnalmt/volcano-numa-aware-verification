# Verification Progress: GPU NUMA Awareness E2E

## Scope

- Volcano PR: https://github.com/volcano-sh/volcano/pull/5095
- Resource Exporter PR: https://github.com/volcano-sh/resource-exporter/pull/12
- Reference scripts: https://github.com/pmady/gpu-numa-test
- Goal: verify end-to-end behavior in a real cluster with GPU NUMA topology

---

## Phase 1: Server Baseline (`lsps064x`)

### 1.1 Host and Runtime Context

- Server: `lsps064x`
- Purpose: GPU worker/control environment for Volcano GPU NUMA verification
- Date: `<YYYY-MM-DD>`
- Operator: `<name>`
- Status: `IN PROGRESS`

### 1.2 GPU Operator Presence

- Check: NVIDIA GPU Operator components are installed and healthy.
- Command:

```bash
kubectl get pods -n gpu-operator
```

- Observed:
  - Namespace exists: `<yes/no>`
  - Pods healthy: `<N>/<N> Running`
  - Notable restarts/errors: `<none/details>`
- Evidence: `<paste output or screenshot path>`

### 1.3 Node-Level GPU Visibility (`lsps064x`)

- Check: Kubernetes sees allocatable GPUs on target node.
- Commands:

```bash
kubectl get node lsps064x -o jsonpath='{.status.allocatable.nvidia\.com/gpu}{"\n"}'
kubectl describe node lsps064x
```

- Observed:
  - Allocatable GPUs: `<value>`
  - Node Ready: `<True/False>`
  - GPU-related taints/labels: `<details>`
- Evidence: `<paste relevant snippets>`

### 1.4 Hardware Topology Baseline

- Host check result:

```text
nvidia-smi: command not found on host
```

- Interpretation:
  - This is acceptable when GPU tooling is containerized by GPU Operator.
  - Host-level `nvidia-smi` is not required for Volcano verification if cluster
    GPU resources and operator components are healthy.

- Replacement checks (cluster-centric):

```bash
kubectl get node lsps064x -o jsonpath='{.status.allocatable.nvidia\.com/gpu}{"\n"}'
kubectl get pods -A | grep -E 'nvidia|gpu-operator|device-plugin'
kubectl -n gpu-operator logs daemonset/nvidia-device-plugin-daemonset --tail=200
```

- Optional topology evidence (from an NVIDIA-enabled pod):

```bash
# Example only: run nvidia-smi inside a pod that has NVIDIA tools available
kubectl -n gpu-operator exec -it <nvidia-pod> -- nvidia-smi topo -m
```

- Observed:
  - Cluster GPU visibility: `<pass/fail>`
  - Device plugin health: `<pass/fail>`
  - Topology evidence source: `<host/pod/unavailable>`

### 1.5 Kubelet Topology Configuration (Precondition)

- Check: Topology Manager policy is suitable (`best-effort` or `restricted`).
- Commands:

```bash
ps -ef | grep kubelet | grep topology-manager-policy
```

- Observed:
  - Policy: `<best-effort/restricted/single-numa-node/none>`
  - CPU manager policy (if set): `<value>`
- Evidence: `<paste output>`

### 1.6 Phase 1 Conclusion

- Result: `<PASS/BLOCKED/PARTIAL>`
- Summary: `<short conclusion>`
- Blocking issues:
  - `<issue 1>`
  - `<issue 2>`
- Next step: deploy PR builds and validate `Numatopology` GPU details plus
  scheduling behavior under `numaaware`.
