# ADR-0006: Control Plane — Managed by Default

**Status:** Accepted

## Context
Running your own control plane (API server, etcd, scheduler HA) is a real operational burden that
adds little differentiated value for most organizations. Every major cloud offers a managed option
that handles this.

## Decision
Default to **managed Kubernetes** (EKS / GKE / AKS). Self-host only when there's a specific, named
reason: regulatory/data-sovereignty requirement, air-gapped environment, edge deployment with no
cloud connectivity, or genuine in-house control-plane expertise with a reason to use it.

## Consequences
- Less control-plane engineering time spent; more available for workload standards, security policy,
  developer experience, and cost visibility — the parts that actually differentiate a platform team.
- Self-hosted exception cases must document *why* explicitly, in a follow-up ADR, not by default drift.

## References
- https://docs.aws.amazon.com/eks/latest/best-practices/control-plane.html
- https://docs.cloud.google.com/kubernetes-engine/docs/concepts/cluster-architecture
- https://learn.microsoft.com/en-us/azure/aks/core-aks-concepts
