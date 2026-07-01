# Multi-Tenancy — Namespace-per-Tenant Default

ADR-0005. The default tenancy tier: namespace isolation enforced with RBAC,
ResourceQuota, and NetworkPolicy together — not any one of the three alone.

- `tenant-namespace-template.yaml` — Namespace + ResourceQuota + NetworkPolicy
  (default-deny cross-tenant ingress **and** egress, re-allowing only
  same-tenant traffic and DNS) + RoleBinding (tenant group bound to `edit`
  within their own namespace — see the hardening note in the manifest about
  replacing `edit` with a curated Role). Duplicate per tenant, replacing
  `team-payments`.

**Scope note:** this is the namespace-isolated default tier only. The
hard-isolation tier (vCluster, for external customers, regulated workloads,
or tenants needing their own CRDs/webhooks) is documented in
`docs/adr/0005-multi-tenancy.md` but has no manifest here yet — vCluster
setup is environment-specific (Helm values, host-cluster capacity planning)
and is a real follow-up piece of work, not implied by this template.
