# Observability & Telemetry — OpenTelemetry Pipeline

Two deliberately separate paths:

- **In-cluster:** an OpenTelemetry Collector pipeline covering traces, logs,
  and metrics, with a PII redaction processor in the collection path before
  anything leaves the cluster.
  - `otel-collector-config.yaml` — Collector pipeline config (receivers →
    processors → exporters) as a ConfigMap.
  - `otel-collector-deployment.yaml` — Deployment + Service running the
    collector in-cluster, mounting the config above.
- **Local:** a runnable docker compose stack using **Grafana Alloy** as the
  local collector/distribution, with Tempo, Loki, Prometheus, and Grafana
  behind it.
  - `local-dev/compose.yml` — the stack.
  - `local-dev/config.alloy` — checked-in Alloy pipeline config.
  - `local-dev/prometheus.yml`, `local-dev/tempo.yaml`, `local-dev/loki.yaml`,
    `local-dev/grafana/provisioning/` — backend configs, all checked in.

The local Compose path is Alloy-based because Alloy is a practical
Grafana-native local collector for Tempo/Loki/Prometheus. The in-cluster
example remains an OpenTelemetry Collector ConfigMap. No extraction, `yq`,
`sed`, or generated files are required — everything the stack mounts is
committed.

## Local Alloy dev loop

```bash
cd observability-telemetry/local-dev
docker compose config   # sanity-check the stack definition
docker compose up
```

Endpoints once up:

| Endpoint | URL |
|---|---|
| Alloy UI | http://localhost:12345 |
| OTLP gRPC ingest | localhost:4317 |
| OTLP HTTP ingest | http://localhost:4318 |
| Grafana | http://localhost:3000 |
| Tempo | http://localhost:3200 |
| Loki | http://localhost:3100 |
| Prometheus | http://localhost:9090 |

Point application telemetry at the stack with
`OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318` (OTLP HTTP) or
`localhost:4317` (OTLP gRPC), depending on your SDK/exporter.

Grafana starts with Tempo, Loki, and Prometheus datasources pre-provisioned.
Prometheus runs with `--web.enable-remote-write-receiver` so Alloy can push
metrics to it.

In the local Alloy pipeline, redaction/sanitization is applied to **traces
and logs**; metrics receive batching only. The in-cluster Collector config
runs its `redaction` processor on all three signals — the two configs are
intentionally not byte-for-byte equivalent.

This local stack is single-node, no auth, no persistence guarantees beyond
basic local volumes. It is not production.

## Honest scope

This is a **pipeline reference**, not a production observability platform.
It shows the shape of the collector config and how PII redaction fits in the
pipeline. It does **not** include: Tempo/Loki/Prometheus HA deployment specs,
retention/storage sizing, alerting rules, or the trace-to-source-line mapping
described in the original blog draft — that's an IDE/CI integration feature
(e.g. embedding commit SHA in span attributes and resolving it against your
source host), not something the collector config itself provides. If you
want that, it's a real follow-up piece of work, not implied by this pipeline.

## Why local-dev exists here specifically

This is the one folder in the repo with a docker compose path (vs. the rest,
which are Kubernetes-native). Reason: iterating on a telemetry pipeline
config is faster against `docker compose up` than against a full cluster —
this is a genuine dev-loop optimization, not an attempt to make the whole
repo dev/stage/prod-environment-layered.
