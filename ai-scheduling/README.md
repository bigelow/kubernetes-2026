# AI Scheduling — Dynamic Resource Allocation (DRA)

ADR-0008. DRA (GA in v1.34) lets workloads request accelerators declaratively
via claims, instead of the old Device Plugin extended-resource model.

- `dra-deviceclass-resourceclaim.yaml` — a `DeviceClass` describing a class of
  GPU, a `ResourceClaimTemplate` requesting a slice of one, and an example Pod
  consuming it.

**Scope note:** this shows the request/claim shape. It does not cover cluster
autoscaler integration for GPU node pools, multi-node training orchestration,
or model-serving frameworks (KServe, Ray, etc.) — those are separate,
larger decisions that build on top of DRA rather than being part of it.

As of v1.37, `ResourceClaim.status.devices` (per-device status reported by the
driver) is GA; it is populated by the driver at allocation time, so nothing in
this manifest changes. Gang scheduling via the Workload/PodGroup APIs
(`scheduling.k8s.io/v1beta1`) is Beta in v1.37 and deliberately not shown —
no Beta APIs in this folder.
