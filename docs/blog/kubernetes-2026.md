# Kubernetes in 2026 — repo alignment notes

The original blog draft is not stored in this repo. This file holds the
**corrected claim language** the published post must use, so the post and the
repo can't drift apart. If the post says something this file doesn't support,
the post is wrong.

## Scope claim (replaces the old "every decision" sentence)

Old, too broad — do not use:

> "Every decision above has a working counterpart in an accompanying
> reference repository..."

Corrected:

> The accompanying reference repository turns the platform decisions this
> post explicitly chooses into ADRs, manifests, Terraform, CI checks, and a
> runnable local observability loop. Some ecosystem topics discussed in the
> post — Windows nodes, KEDA/Knative, full vCluster setup, Cilium
> installation, and concrete stateful operators — are intentionally treated
> as context or documented follow-up work rather than implemented components.

## "What's Inside" — accurate per-folder claims

- **security-policy** — CEL admission policies. The image-registry validating
  policy covers containers, initContainers, and ephemeralContainers. The
  resource-defaults mutating policy is illustrative (containers +
  initContainers) and requires server-side dry-run validation on v1.36+
  before production use.
- **observability-telemetry** — in-cluster OTel Collector pipeline reference;
  `local-dev/` is a **runnable** Grafana Alloy + Tempo/Loki/Prometheus/Grafana
  stack via `docker compose up`. Not production.
- **cost-allocation** — a MutatingAdmissionPolicy **intended to auto-label**
  new namespaces with `cost-center` (illustrative, pending server-side
  validation), plus a cost-export CronJob skeleton.
- **workloads** — the StatefulSet is the shape an operator would manage; no
  operator or CRD is included.
- **multi-tenancy** — the namespace-per-tenant tier is implemented; the
  vCluster hard-isolation tier is documented (ADR-0005) but not implemented.
- **CI** — kubeconform validates Kubernetes manifests from the platform
  folders, not all YAML in the repo.
