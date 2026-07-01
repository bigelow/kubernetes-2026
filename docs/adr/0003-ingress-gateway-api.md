# ADR-0003: Traffic Routing — Gateway API for New Work

**Status:** Accepted

## Context
Two distinct things happened and are easy to conflate:
1. The **Ingress API** itself is stable/GA and has no planned removal from Kubernetes.
2. The **ingress-nginx controller project** (one specific implementation) was retired by
   Kubernetes SIG Network and the Security Response Committee in March 2026 — no further
   releases, bugfixes, or security patches. Existing deployments keep working but are now
   unmaintained.

Gateway API is the project's official successor direction for traffic routing generally, independent
of the ingress-nginx retirement.

## Decision
- New traffic-routing work targets **Gateway API**, not Ingress.
- Existing Ingress objects are not an emergency — the API isn't going away.
- Existing **ingress-nginx controller** deployments get a migration plan (to a maintained Gateway API
  controller such as Envoy Gateway or Cilium's own Gateway API support — a natural fit since Cilium
  is already ADR-0002's default CNI — or a commercially-supported NGINX fork), not a same-day rewrite.

## Consequences
- Two routing models coexist during migration; document which namespaces/teams are on which.
- Unmaintained ingress-nginx is a growing security liability the longer it's left in place.

## References
- https://kubernetes.io/docs/concepts/services-networking/ingress/
- https://kubernetes.io/docs/concepts/services-networking/gateway/
- https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/ (retirement announcement — best-effort maintenance ends March 2026)
- https://kubernetes.io/blog/2026/01/29/ingress-nginx-statement/ (Steering + Security Response Committee statement)
