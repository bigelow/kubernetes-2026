# ADR-0007: Admission Control — CEL-Based Policies Over Webhooks

**Status:** Accepted

## Context
ValidatingAdmissionPolicy reached GA in v1.30; MutatingAdmissionPolicy reached GA in v1.36. Both let
teams express admission logic as native, CEL-based Kubernetes objects, running in-process in the
API server — no external webhook service, no TLS certs to manage, no webhook availability as a
cluster-wide single point of failure.

## Decision
New admission-control logic (validation and mutation) is written as **Validating/MutatingAdmissionPolicy**
objects by default. Reach for external webhooks (Kyverno, OPA Gatekeeper) only when policy logic
exceeds what CEL can reasonably express, or when the existing webhook ecosystem/tooling is already
load-bearing.

## Consequences
- Lower operational surface (no webhook pods/certs to run and rotate) and lower admission latency.
- CEL has a learning curve distinct from Rego (OPA) or Kyverno's YAML-native policies.
- Existing Kyverno/OPA investments don't need to be ripped out — this is a default for new policy,
  not a mandated migration.

## References
- https://kubernetes.io/blog/2024/04/24/validating-admission-policy-ga/
- https://kubernetes.io/docs/reference/access-authn-authz/mutating-admission-policy/
