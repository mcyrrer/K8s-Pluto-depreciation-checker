# Test for kustomization with deprecated APIs

This test case contains a kustomization overlay that references a Deployment using a deprecated apiVersion (apps/v1beta1).

- `base/deployment.yaml` uses `apiVersion: apps/v1beta1` (deprecated)
- `base/kustomization.yaml` references the deployment
- `overlays/dev/kustomization.yaml` references the base

This should trigger a deprecation warning when checked by the depreciation-checker script.
