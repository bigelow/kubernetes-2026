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
