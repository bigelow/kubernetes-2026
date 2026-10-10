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
- `mutatingadmissionpolicy-resource-defaults.yaml` — **fills in** the
  CPU/memory requests/limits a container or initContainer omits, emitting only
  the missing keys (backstop for ADR-0009; `scripts/validate.py` catches the
  same gap — including ephemeralContainers — at CI time). It is a pure gap
  filler: a requests-only container stays requests-only (Burstable QoS
  preserved — ADR-0009 asks for both to be set, not for them to be equal), a
  limits-only container gets requests copied from limits (the same defaulting
  the API server applies on its own), and the fixed defaults apply only to a
  key absent from both. **Verified against
  v1.37** (kindest/node v1.37.0, 2026-10-10) via server-side dry-run and live
  admission testing, including containers that carry atomic fields
  (`command`, `capabilities.drop`) under `IfNeeded` reinvocation — the shape
  the previous expression denied. Ephemeral containers are deliberately not
  mutated.

**Scope note:** these are two representative policies, not a full policy
catalog. A real platform would also cover privilege escalation, host
namespaces, and label/annotation requirements — same CEL pattern, more rules.

Both policies are ordinary API objects. v1.37 also graduated **manifest-based
admission control** to Beta (enabled by default): the same
`admissionregistration.k8s.io/v1` policy and binding kinds can be loaded from
files on the API server's disk, enforced from startup and not deletable via the
API. Not used here — it's Beta, and it needs kube-apiserver configuration that
managed control planes (ADR-0006) generally don't expose — but note it reserves
the `.static.k8s.io` name suffix, which these policies don't use.
