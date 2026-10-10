# ADR-0008: Accelerator Scheduling — Dynamic Resource Allocation (DRA)

**Status:** Accepted

## Context
Kubernetes has historically handled GPUs/accelerators via workaround-heavy Device Plugins. Dynamic
Resource Allocation (DRA) reached GA in v1.34, giving workloads a native way to request and share
specialized hardware (GPUs, FPGAs) with finer-grained control than the old model.

## Decision
New AI/ML/accelerator workloads request hardware via **DRA**, not legacy Device Plugin resource
requests, where the cluster's Kubernetes version supports it.

## Consequences
- Finer-grained sharing (e.g. GPU slicing) and cleaner resource accounting than Device Plugins.
- Kubernetes gives scheduling primitives; it does not solve model serving, multi-node training
  orchestration, or inference autoscaling on its own — those remain separate architecture decisions.
- Accelerator hardware is expensive relative to standard compute — treat GPU/accelerator utilization
  as a first-class input to cost review (ADR-0009), not an afterthought.
- Requires v1.34+; older clusters stay on Device Plugins until upgraded.
- v1.37 graduated `ResourceClaim.status.devices` (driver-reported per-device status, including
  standardized network-interface data), DRA device taints/tolerations, and DRA-backed extended
  resources to GA. None of them change the DeviceClass/ResourceClaimTemplate request shape in
  `ai-scheduling/`; the status is written by the driver, not the manifest.
- Gang scheduling through the Workload/PodGroup APIs (`scheduling.k8s.io/v1beta1`, behind the
  `GenericWorkload` feature gate, off by default) is Beta in v1.37. It matters for multi-node
  training, which this ADR already leaves to a separate decision — a scope note only; no Beta API
  manifests are included here.

## References
- https://kubernetes.io/docs/concepts/scheduling-eviction/dynamic-resource-allocation/
- https://kubernetes.io/docs/concepts/scheduling-eviction/gang-scheduling/ (Beta since v1.37)
- https://kubernetes.io/blog/2026/08/26/kubernetes-v1-37-release/
