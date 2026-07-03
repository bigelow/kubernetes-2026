# local/ — the reference architecture on a laptop

Runs the repo's manifests on a local k3s-in-Docker cluster (k3d), ending at a
Grafana dashboard fed by real telemetry from a demo workload. The reference
manifests are consumed **as written** from their original directories via
kustomize; every local deviation is an explicit, commented patch in this
directory.

## Prerequisites

- Docker (Docker Desktop works)
- [mise](https://mise.jdx.dev) — everything else (k3d, kubectl, helm) is
  pinned in the root `mise.toml`: run `mise install` once.

## Up / down

```sh
mise run local-up     # k3d cluster + core manifests + observability spine
mise run local-down   # delete the cluster (all state is inside it)
```

`local-up` is idempotent; re-run it after changing overlays or the demo app.

## What you get

- **Cluster** `k2026`: 1 server + 2 agents, k3s `v1.36.2-k3s1` — same minor
  as the repo's v1.36 target, so there is **no version gap** to work around;
  the GA `admissionregistration.k8s.io/v1` Mutating/ValidatingAdmissionPolicy
  manifests apply as-is.
- **Reference core**, applied unmodified except where noted below:
  namespaces, all three CEL admission policies, the tenant template
  (`team-payments`), and the OTel collector.
- **Demo app** (`local/demo-app/`, `team-demo` namespace): ~70-line Flask
  service, zero-code OTel instrumentation, structlog JSON logging.
  `GET /api/orders` sleeps 20–300 ms and fails ~10% of the time so the
  dashboard has real shape.
- **Observability spine** (Helm, pinned in `local/up.sh`, values in
  `local/helm/`): Alloy 1.10.0, Loki 7.0.0 (single binary), Tempo 1.24.4
  (single binary), Mimir 6.1.0, Grafana 10.5.15.
- **Dashboard as code**: `local/dashboards/demo-app.json`, provisioned via
  ConfigMap + Grafana sidecar. No UI clicking.

Telemetry path (matches the reference intent; only the exporter endpoints
are local):

```
demo-app --OTLP--> otel-collector (reference pipeline, PII redaction)
         --OTLP--> alloy --traces--> tempo
                         --logs----> loki   (OTLP-native /otlp)
                         --metrics-> mimir  (prometheus remote_write)
                                        \--> grafana (provisioned datasources)
```

## URLs

| What | Where |
|---|---|
| Grafana | http://grafana.localhost:8080 — `admin` / `k2026-local` |
| Demo app | http://demo.localhost:8080/api/orders |

(`*.localhost` resolves to 127.0.0.1 in browsers and modern resolvers; port
8080 is the k3d loadbalancer mapped to Traefik.)

Generate traffic: `for i in $(seq 50); do curl -s http://demo.localhost:8080/api/orders > /dev/null; done`

Dashboard: Grafana → Dashboards → **Demo App — RED** (provisioned).

## Local deltas from the reference (and why)

Everything below lives in `local/`; the reference files are untouched.

| Delta | Where | Why |
|---|---|---|
| `platform-observability` Namespace created, labeled `tier: platform-system` | `kustomize/core/namespace-platform-observability.yaml` | The reference deploys into this namespace but ships no manifest for it. The label uses the image-registry policy's own exemption so upstream `otel/grafana/...` images can run. |
| `kube-system` labeled `tier: platform-system` | `up.sh` | k3s system images (traefik, coredns, servicelb) aren't from the approved registry; without the exemption the reference VAP would deny them on any pod re-creation. |
| Collector: 1 replica, `DEPLOY_ENV=local` | `kustomize/core/patch-otel-collector-deployment.yaml` | Laptop. |
| Collector exporters → Alloy | `kustomize/core/patch-otel-collector-config.yaml` | The reference exports straight to `tempo`/`loki`/`prometheus` services. Locally the spine is collector → Alloy → Tempo/Loki/Mimir. Receivers + processors (incl. PII redaction) are byte-identical to the reference. |
| **Bugfix ×2**: resource-defaults MutatingAdmissionPolicy | `kustomize/core/patch-map-resource-defaults.yaml` | Two live-discovered bugs, both **candidates for upstreaming into `security-policy/`**. (1) The reference expression returns the whole container for already-satisfied containers; an ApplyConfiguration may not contain atomic fields (`securityContext.capabilities.drop`), so the API server **denies** such pods — including the repo's own otel-collector on restart, and any defaulted container with atomic fields via `IfNeeded` reinvocation. (2) For containers with requests but no limits, the fixed default limits can end up *below* the existing requests (mimir-kafka asks 1 CPU/1Gi), which invalidates the pod. Patch: already-limited containers get an SSA no-op (`{name: c.name}`); un-limited ones get `limits := requests` when requests exist, else the fixed defaults. |
| `team-demo` tenant namespace | `kustomize/demo/namespace-team-demo.yaml` | Follows the tenant template's "duplicate per tenant" instruction. Laptop-sized quota; egress additionally allows OTLP to the collector (the template's default-deny would silently drop telemetry — a real gap for any telemetry-emitting tenant); ingress additionally allows Traefik; no cost-center label on purpose so the reference MAP provably injects `unassigned`. |
| Demo image tag `registry.internal.example.com/demo-app` | `up.sh`, `kustomize/demo/demo-app.yaml` | Built locally and imported into k3d under the approved-registry name so the reference image VAP passes as written (`imagePullPolicy: Never` — the registry doesn't exist). |
| Demo container omits `resources` | `kustomize/demo/demo-app.yaml` | Deliberate: the reference resource-defaults MAP must inject them or the pod can't pass the tenant quota — scheduling doubles as a live policy test. |
| Traefik Ingress instead of Gateway API | `kustomize/demo/demo-app.yaml`, `helm/grafana-values.yaml` | ADR-0003 targets Gateway API with an Envoy Gateway class; phase 1 keeps k3s's stock Traefik rather than installing a second controller. Phase 2 candidate. |
| Mimir: smallest distributed footprint, not monolithic | `helm/mimir-values.yaml` | The official chart has no `-target=all` mode; this is 1 replica per required component, no zone awareness, bundled MinIO, everything optional off. The chart's default Mimir 3.x ingest-storage architecture (Kafka between distributor and ingester) is switched back to the classic push path — no broker on a laptop. The query-scheduler stays: the chart wires the read path through it unconditionally. |

Not applied in phase 1: `traffic-management/` (needs Gateway API CRDs +
controller), `ai-scheduling/` (no GPUs/DRA driver in k3d),
`cost-allocation/cost-export-cronjob.yaml` (skeleton image),
`workloads/statefulset-example.yaml` (3-replica DB is not laptop-shaped).

## Verified live (not just applied)

- All manifests in scope apply clean against the real v1.36.2 API server.
- `restrict-image-registries` VAP: denies `nginx:latest` in `team-demo`.
- `inject-cost-label` MAP: `team-demo` created without the label carries
  `cost-center=unassigned`.
- `default-resource-requests` MAP (patched): injected
  `100m/128Mi + 500m/512Mi` into the demo container.
- Full telemetry path: traffic on `/api/orders` shows up in the provisioned
  dashboard (RED metrics from Mimir, JSON logs from Loki, traces from Tempo).
