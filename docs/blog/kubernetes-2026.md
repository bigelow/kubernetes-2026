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

- **security-policy** — CEL admission policies, **verified against v1.36**
  (kindest/node v1.36.1, server-side dry-run + live admission testing). The
  image-registry validating policy rejects unapproved images on containers and
  initContainers (and any ephemeralContainers already on the Pod object);
  ephemeral containers injected later via the `pods/ephemeralcontainers`
  subresource are not gated at admission, and CI-side `validate.py` checks
  them instead. The resource-defaults mutating policy (containers +
  initContainers) injects defaults, confirmed live.
- **observability-telemetry** — in-cluster OTel Collector pipeline reference;
  `local-dev/` is a **runnable** Grafana Alloy + Tempo/Loki/Prometheus/Grafana
  stack via `docker compose up`. Not production.
- **cost-allocation** — a MutatingAdmissionPolicy that **auto-labels** new
  namespaces with `cost-center` (**verified against v1.36**: kindest/node
  v1.36.1, server-side dry-run + live admission testing, existing labels
  preserved), plus a cost-export CronJob skeleton.
- **workloads** — the StatefulSet is the shape an operator would manage; no
  operator or CRD is included.
- **multi-tenancy** — the namespace-per-tenant tier is implemented; the
  vCluster hard-isolation tier is documented (ADR-0005) but not implemented.
- **CI** — kubeconform validates Kubernetes manifests from the platform
  folders, not all YAML in the repo.
