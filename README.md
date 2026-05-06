# Volcano GPU NUMA Verification

This repository tracks end-to-end verification progress for:

- https://github.com/volcano-sh/volcano/pull/5095
- https://github.com/volcano-sh/resource-exporter/pull/12

It is focused on documenting real-cluster validation evidence, decisions,
findings, and follow-up actions.

## Structure

- `docs/verification-progress.md` - living verification log
- `VERSIONS.md` - pinned upstream PR commits under test
- `evidence/` - command outputs and screenshots grouped by host/date

## Notes

- The upstream helper repo (https://github.com/pmady/gpu-numa-test) is used
  as reference only and adapted as needed.

## Resource Exporter Verification Runbook

### Prerequisites

- `kubectl` configured to the target cluster
- `resource-exporter` PR12 image available in internal registry
- Node-scoped installers available under `evidence/2026-05-06/`

### 1) Collect GPU NUMA baseline evidence

```bash
cd /home/uih20178/Github/volcano-numa-aware-verification
./scripts/numa-check.sh lsps044x /home/uih20178/Github/volcano-numa-aware-verification/evidence/2026-05-06
./scripts/numa-check.sh lsps064x /home/uih20178/Github/volcano-numa-aware-verification/evidence/2026-05-06
```

### 2) Deploy resource-exporter and collect runtime evidence

```bash
cd /home/uih20178/Github/volcano-numa-aware-verification
./scripts/collect-resource-exporter-evidence.sh lsps044x
./scripts/collect-resource-exporter-evidence.sh lsps064x
```

### 3) Validate captured artifacts

Check these files for each node:

- `apply-<node>.txt`
- `rollout-<node>.txt`
- `pods-resource-topology-<node>.txt`
- `logs-resource-topology-<node>.txt`
- `numatopologies-list-after-<node>.txt`
- `numatopologies-after-<node>.yaml`
