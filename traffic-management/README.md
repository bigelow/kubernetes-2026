# Traffic Management — Gateway API

ADR-0003. Covers the Gateway itself, TLS termination, and weighted traffic
splitting (the canary-release pattern Ingress never handled cleanly).

- `gateway-httproute.yaml` — Gateway + basic HTTPRoute (from the original reference).
- `httproute-traffic-split.yaml` — canary example: 90/10 weighted split across
  two backend Services using the same HTTPRoute object.

**Scope note:** these are illustrative manifests for a Gateway API implementation
(Envoy Gateway is assumed via `gatewayClassName`). They are not a full ingress
migration toolkit — swap `gatewayClassName` for whatever controller you run.
