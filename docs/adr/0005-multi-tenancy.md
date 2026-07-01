# ADR-0005: Multi-Tenancy — Namespace-per-Tenant Default, vCluster for Hard Isolation

**Status:** Accepted

## Context
Kubernetes has no first-class concept of "tenant." Official docs describe two primary sharing models:
namespace-per-tenant (cheap, well-supported, but doesn't cover cluster-scoped resources like CRDs,
StorageClasses, webhooks) and virtual-control-plane-per-tenant (stronger isolation, higher cost).

## Decision
- **Default tier:** namespace-per-tenant, enforced with RBAC + ResourceQuota + NetworkPolicy.
- **Hard-isolation tier** (external customers, regulated workloads, or tenants needing their own
  CRDs/webhooks): virtual control plane via vCluster, on top of the shared host cluster.
- Don't reach for hard isolation by default — it costs more to operate and most internal-team use
  cases don't need it.

## Consequences
- Two tenancy tiers means two support models; document which tenants are on which and why.
- Namespace tier is cheap to scale; vCluster tier requires its own capacity planning per tenant.

## References
- https://kubernetes.io/docs/concepts/security/multi-tenancy/
