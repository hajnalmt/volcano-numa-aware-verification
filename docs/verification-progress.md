# Verification Progress: GPU NUMA Awareness E2E

## Scope

- Volcano PR: https://github.com/volcano-sh/volcano/pull/5095
- Resource Exporter PR: https://github.com/volcano-sh/resource-exporter/pull/12
- Reference scripts: https://github.com/pmady/gpu-numa-test
- Goal: verify end-to-end behavior in a real cluster with GPU NUMA topology

## Lab inventory

- `lsps064x`: 8 GPU, cross-NUMA topology
- `lsps044x`: 2 GPU, single-NUMA topology
- Verification intent:
  - Use `lsps064x` as the primary node for cross-NUMA scheduling behavior.
  - Use `lsps044x` as a baseline/control node for single-NUMA behavior.

---

## Phase 1: Server Baseline (`lsps064x`)

### 1.1 Host and Runtime Context

- Server: `lsps064x`
- Purpose: GPU worker/control environment for Volcano GPU NUMA verification
- Date: `2026-04-27`
- Operator: `hajnalmt`
- Status: `PARTIAL`

### 1.2 GPU Operator Presence

- Check: NVIDIA GPU Operator components are installed and healthy.
- Command:

```bash
kubectl get pods -n gpu-operator
```

- Observed:
  - Namespace exists: `yes`
  - Node-scoped components on `lsps064x` are healthy: GFD, toolkit, device plugin,
    DCGM exporter, MIG manager, operator validator (`Running`), CUDA validator
    (`Completed`).
  - Notable restarts/errors: `none on lsps064x`.
- Evidence:
  - `kubectl get pods -n gpu-operator -o wide --field-selector spec.nodeName=lsps064x`

### 1.3 Node-Level GPU Visibility (`lsps064x`)

- Check: Kubernetes sees expected GPU resources on target node.
- Commands:

```bash
kubectl get node lsps064x -o jsonpath='{.status.allocatable.nvidia\.com/gpu}{"\n"}'
kubectl describe node lsps064x
```

- Observed:
  - Node Ready: `True`
  - Node is cordoned: `true` (`node.kubernetes.io/unschedulable:NoSchedule`)
  - Physical GPU labels: `nvidia.com/gpu.count=8`,
    `nvidia.com/gpu.product=NVIDIA-H100-80GB-HBM3`
  - Allocatable resources are MIG profiles, not full GPUs:
    - `nvidia.com/gpu=0`
    - `nvidia.com/mig-2g.20gb=8`
    - `nvidia.com/mig-3g.40gb=12`
- Evidence:
  - `kubectl get node lsps064x -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}{"\n"}{.spec.unschedulable}{"\n"}{.spec.taints}{"\n"}'`
  - `kubectl get node lsps064x -o json | jq -r '.status.allocatable | to_entries[] | select(.key|test("nvidia")) | "\(.key)=\(.value)"'`
  - `kubectl get node lsps064x -o json | jq -r '.metadata.labels | to_entries[] | select(.key|startswith("nvidia.com/")) | "\(.key)=\(.value)"'`

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
  - Cluster GPU visibility: `pass` (GPU operator labels/resources present)
  - Device plugin health: `pass` (`nvidia-device-plugin-daemonset-g767g Running`)
  - Topology evidence source: `pending pod-based nvidia-smi topo -m`

### 1.5 Kubelet Topology Configuration (Precondition)

- Check: Topology Manager policy is suitable (`best-effort` or `restricted`).
- Commands:

```bash
ps -ef | grep kubelet | grep topology-manager-policy
```

- Observed:
  - Policy: `pending` (not collected yet from kubelet flags/config)
  - CPU manager policy (if set): `pending`
- Evidence: `pending`

### 1.6 Phase 1 Conclusion

- Result: `PARTIAL`
- Summary: `GPU Operator stack is healthy on lsps064x, but node is cordoned and exposes only MIG allocatable resources (nvidia.com/gpu=0).`
- Blocking issues:
  - `lsps064x is unschedulable (cordoned)`
  - `verification workload specs must use MIG resources or MIG must be disabled for full-GPU tests`
- Next step: deploy PR builds and validate `Numatopology` GPU details plus
  scheduling behavior under `numaaware`.

---

## Phase 1b: Server Baseline (`lsps044x`)

### 1b.1 Host and Runtime Context

- Server: `lsps044x`
- Purpose: control/baseline node (single-NUMA GPU topology)
- Date: `2026-04-27`
- Operator: `hajnalmt`
- Status: `PARTIAL`

### 1b.2 Cluster GPU Visibility

- Check: Kubernetes reports expected GPU resources.
- Commands:

```bash
kubectl get node lsps044x -o jsonpath='{.status.allocatable.nvidia\.com/gpu}{"\n"}'
kubectl describe node lsps044x
```

- Observed:
  - Node Ready: `True`
  - Node is cordoned: `true` (`node.kubernetes.io/unschedulable:NoSchedule`)
  - Physical GPU labels: `nvidia.com/gpu.count=2`,
    `nvidia.com/gpu.product=NVIDIA-A100-PCIE-40GB`
  - MIG mode is enabled (`nvidia.com/mig.strategy=mixed`)
  - Allocatable resources are MIG profiles:
    - `nvidia.com/mig-2g.10gb=4`
    - `nvidia.com/mig-3g.20gb=2`
    - `nvidia.com/gpu` key is not allocatable on this node

### 1b.3 Topology Baseline

- Objective: confirm this node behaves as single-NUMA for available GPUs.
- Evidence options:
  - `nvidia-smi topo -m` from NVIDIA-enabled pod, or
  - `Numatopology` CR evidence once resource-exporter PR build is deployed.

- Observed:
  - Single-NUMA confirmed: `pending`
  - Evidence source: `pending (pod topology or Numatopology CR after PR deploy)`

### 1b.4 Phase 1b Conclusion

- Result: `PARTIAL`
- Summary: `Node baseline is healthy, but it is cordoned and currently exposes MIG resources only, not full GPUs.`
