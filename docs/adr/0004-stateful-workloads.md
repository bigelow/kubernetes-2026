# ADR-0004: Stateful Workloads — StatefulSets + Operators

**Status:** Accepted

## Context
Kubernetes now explicitly targets stateless, stateful, and data-processing workloads. StatefulSets
give stable identity, ordered deployment, and stable network identity — but Kubernetes does not
turn databases/queues into managed services on its own. Backup, restore, replication, and failure
domains remain the operator's responsibility.

## Decision
Stateful production workloads (databases, message buses, caches with persistence) run as
**StatefulSets managed by a purpose-built operator** (e.g. a Postgres or Kafka operator), never as
bare Deployments with a PVC bolted on.

## Consequences
- Correct handling of backup/restore, failover, and version upgrades — the operator encodes that logic.
- Adds a dependency on the operator's maturity and maintenance; vet operators before adopting.
- For workloads where a managed cloud database (RDS, Cloud SQL) is available and there's no strong
  reason to run it in-cluster, prefer the managed service instead of reinventing operational maturity.

## References
- https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
- https://kubernetes.io/docs/concepts/overview/
