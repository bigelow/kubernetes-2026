# Security Policy — Admission Control Without Webhooks

ADR-0007. Two policies, both CEL-based and running in-process in the API server —
no webhook Deployment, no TLS cert rotation, no webhook-availability SPOF.

- `validatingadmissionpolicy-image-registry.yaml` — **rejects** unapproved
  images on containers and initContainers (and any ephemeralContainers already
  present on the Pod object) at Pod CREATE/UPDATE. It matches
  `resources: ["pods"]`, **not** the `pods/ephemeralcontainers` subresource, so
  ephemeral containers injected later (e.g. `kubectl debug`) are **not** gated
  at admission by this policy; `scripts/validate.py` still checks
  ephemeralContainers at CI time.
- `mutatingadmissionpolicy-resource-defaults.yaml` — **injects** default
  CPU/memory requests/limits when a container or initContainer omits them
  (backstop for ADR-0009; `scripts/validate.py` catches the same gap —
  including ephemeralContainers — at CI time). **Verified against v1.36**
  (kindest/node v1.36.1, 2026-07-01) via server-side dry-run and live
  admission testing. Ephemeral containers are deliberately not mutated.

**Scope note:** these are two representative policies, not a full policy
catalog. A real platform would also cover privilege escalation, host
namespaces, and label/annotation requirements — same CEL pattern, more rules.
