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
