# Workloads — Stateful Example

ADR-0004. Shows the StatefulSet shape for stateful production workloads.

- `statefulset-example.yaml` — a 3-replica StatefulSet with persistent
  `volumeClaimTemplates` and mandatory resource requests/limits (ADR-0009).

**Scope note:** ADR-0004 calls for stateful workloads to run as StatefulSets
*managed by a purpose-built operator* (e.g. a Postgres or Kafka operator).
This file shows the StatefulSet shape an operator would manage — the operator
CRD itself is intentionally not included, since operator choice is workload-
specific (e.g. Zalando's postgres-operator vs. Strimzi for Kafka) and isn't a
platform-layer decision this repo makes for you. Do not treat this manifest
alone as production-ready; without an operator, backup, failover, and upgrade
handling are entirely unaddressed.
