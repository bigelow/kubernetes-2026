# Kubernetes Reference Architecture (2026)

A reference architecture for running production Kubernetes, current as of mid-2026 (Kubernetes v1.36).
Built as a personal reference and portfolio piece — every decision is documented as an ADR with its
rationale, and every example manifest is grouped by the platform concern it addresses.

## Why this exists

Kubernetes' core model (pods, controllers, declarative reconciliation) has stayed stable since 2016.
Everything *around* the core — runtime, networking, ingress, multi-tenancy, AI scheduling, cost — has
changed substantially. This repo captures the current state of those decisions in one place, with
working examples instead of just prose.

## Structure

```
docs/adr/                    Architecture Decision Records — one per major design choice
docs/architecture-overview.md   High-level diagram + component walkthrough

traffic-management/          Gateway API: routing, TLS termination, weighted traffic splitting
security-policy/             CEL-based admission control (Validating/MutatingAdmissionPolicy)
observability-telemetry/     OTel Collector pipeline (traces/logs/metrics + PII redaction)
ai-scheduling/                Dynamic Resource Allocation (DRA) for GPU/accelerator workloads
cost-allocation/              Cost-center labeling + usage export skeleton (FinOps)
workloads/                    StatefulSet example (ADR-0004)
multi-tenancy/                Namespace-per-tenant template (ADR-0005)

terraform/modules/            IaC for managed control planes (EKS shown in full; GKE/AKS stubbed)
terraform/environments/       Example environment wiring the modules together
scripts/validate.py           Python validation script (used in CI)
.github/workflows/            CI: YAML validation + Terraform fmt/validate + IaC scan (tflint/trivy)
```

## Decisions covered (see `docs/adr/`)

| # | Decision | Summary |
|---|---|---|
| 0001 | Container runtime | containerd/CRI-O over Docker Engine |
| 0002 | Networking / CNI | Cilium (eBPF) as default, kept pluggable |
| 0003 | Ingress vs Gateway API | Gateway API for new work; plan migration off unmaintained ingress-nginx |
| 0004 | Stateful workloads | StatefulSets + operators, not bare Deployments |
| 0005 | Multi-tenancy model | Namespace-per-tenant default; vCluster for hard isolation tier |
| 0006 | Managed vs self-hosted | Managed control plane (EKS/GKE/AKS) by default |
| 0007 | Security / admission policy | CEL-based Validating/MutatingAdmissionPolicy over webhooks |
| 0008 | AI/GPU scheduling | Dynamic Resource Allocation (DRA) for accelerators |
| 0009 | Cost / FinOps | Requests/limits discipline + per-tenant cost allocation |

## Honest scope

Each top-level platform concern folder's README states plainly what's included and what isn't. In particular:
- **observability-telemetry** is a pipeline reference (collector config + PII redaction), not a
  production Tempo/Loki/Prometheus deployment with HA, retention, or alerting.
- **cost-allocation** shows where a cost tool plugs into the platform; it isn't a replacement for
  OpenCost/Kubecost.
- **ai-scheduling** shows the DRA request/claim shape, not GPU-autoscaler or model-serving integration.

Nothing here claims more maturity than what's actually in the file.

CI also runs `kubeconform` against the Kubernetes manifests in the platform folders (not every
YAML file in the repo — Compose files, workflow YAML, and local-dev backend configs are excluded),
using the community
`datreeio/CRDs-catalog` for Gateway API kinds on top of kubeconform's default schema set. This is
run with `-ignore-missing-schemas`: `MutatingAdmissionPolicy` only went GA in v1.36 (April 2026),
and upstream schema catalogs may not have caught up yet — that flag means "warn on unknown kinds,"
not "silently skip validation." If a resource kind's schema does exist and the manifest is wrong
against it, the job still fails.

Static IaC analysis runs in the `iac-scan` CI job: **tflint** (with the pinned AWS ruleset) over the
Terraform, and **trivy config** over both the Terraform and the Kubernetes manifests. The job fails on
any new finding. Accepted exceptions are carried explicitly — inline `tflint-ignore` annotations for
Terraform and a repo-root `.trivyignore` for trivy — and **every suppression requires a written
rationale** next to it (a deliberate reference-repo choice, a false positive, or an over-strict rule),
never a blanket rule-disable. Run the same scanners locally with `make lint` (skipped gracefully if the
tools aren't installed; CI is the authoritative gate).

## Language choice

This repo is almost entirely YAML, HCL, and Markdown — config, not code. The one script
(`scripts/validate.py`) is Python: it's an I/O-bound CI lint step where readability matters more
than performance, so that's the right tool for it.

If this repo ever grows a **custom operator/controller**, an **admission webhook server**, or a
**distributable CLI**, that's the trigger to reach for **Go** instead — it's the idiomatic language
for the Kubernetes ecosystem (client-go, kubectl, kustomize, operator-sdk, kubeconform all live
there), and fighting that convention has a real cost. ADR-0007 currently avoids needing a webhook
server at all by choosing CEL-native admission policies, which is part of why Go isn't needed yet.
Rust has no natural home in this repo today; it'd become relevant only for a systems-level
component like a custom CNI plugin, which is out of scope here.

## Usage

This is a reference, not a deploy-and-go stack. Terraform modules are illustrative (EKS is fleshed out;
GKE/AKS are stubs following the same pattern) — review and adapt before applying anywhere real.

```bash
make validate   # lint manifests + terraform fmt check
make plan       # terraform plan against example-prod (requires your own backend/credentials)
```

For the observability pipeline specifically, `observability-telemetry/local-dev/` is a runnable
Grafana Alloy + Tempo/Loki/Prometheus/Grafana stack (`docker compose up`) for iterating on the
telemetry pipeline without a cluster. The in-cluster example remains an OTel Collector ConfigMap.

## Sources

Decisions are grounded in official Kubernetes documentation (kubernetes.io) and cloud provider docs
(AWS/GCP/Azure), not third-party summaries. Each ADR lists its sources under "References."
