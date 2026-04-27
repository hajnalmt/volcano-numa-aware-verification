# Versions Under Test

This file pins the exact upstream commits used for verification runs.

## Volcano scheduler change

- PR: https://github.com/volcano-sh/volcano/pull/5095
- Head repository: `pmady/volcano`
- Head branch: `feature/gpu-numa-topology-awareness`
- Head commit: `90123ec55783df9e92e653ac97b92c9b59cbd978`

## Resource exporter change

- PR: https://github.com/volcano-sh/resource-exporter/pull/12
- Head repository: `pmady/resource-exporter`
- Head branch: `feat/gpu-numa-topology`
- Head commit: `3abad69769d6e0e46e9796a8fba1d285a62df718`

## Optional dependency note

- Related API PR: https://github.com/volcano-sh/apis/pull/229
- Track this when validating CRD schema compatibility end to end.

## Test matrix (current lab)

- `lsps064x`: 8 GPU, cross-NUMA topology (primary validation target)
- `lsps044x`: 2 GPU, single-NUMA topology (control/baseline target)
- Current runtime mode on both nodes: MIG enabled (`nvidia.com/mig.strategy=mixed`)
- Current allocatable resources are MIG profiles (not full `nvidia.com/gpu`):
  - `lsps064x`: `nvidia.com/mig-2g.20gb=8`, `nvidia.com/mig-3g.40gb=12`
  - `lsps044x`: `nvidia.com/mig-2g.10gb=4`, `nvidia.com/mig-3g.20gb=2`

Expected behavior for Volcano PR `#5095`:

- 2-GPU jobs should be placeable on both nodes.
- 4-GPU jobs should prefer allocations minimizing NUMA span on `lsps064x`.
- On single-NUMA `lsps044x`, placements should naturally stay within one NUMA
  domain when resources fit.

## Refresh commands

Use these to refresh pinned SHAs later:

```bash
gh api repos/volcano-sh/volcano/pulls/5095 --jq '.head.sha + " " + .head.ref + " " + .head.repo.full_name'
gh api repos/volcano-sh/resource-exporter/pulls/12 --jq '.head.sha + " " + .head.ref + " " + .head.repo.full_name'
```
