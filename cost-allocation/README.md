# Cost Allocation — FinOps Integration

ADR-0009. Two pieces: label discipline enforced at admission time, and a
scheduled export job that joins Kubernetes resource metrics to your billing
data by those labels.

- `mutatingadmissionpolicy-cost-label.yaml` — auto-injects a `cost-center`
  label on new namespaces if one isn't set, so nothing lands unallocated.
  **Verified against v1.36** (kindest/node v1.36.1, 2026-07-01) via
  server-side dry-run and live admission testing, including that existing
  labels are preserved.
- `cost-export-cronjob.yaml` — scheduled job shape for exporting
  usage-by-namespace to wherever your cost data lives.

**Scope note:** `cost-export-cronjob.yaml` is a skeleton — the actual export
logic (join resource-metrics API output against cloud billing export data)
is specific to your billing pipeline and isn't included. In practice, most
teams reach for **OpenCost** or **Kubecost** here rather than hand-rolling
this — the CronJob shape is shown so you can see where such a tool (or a
custom exporter) would plug into the platform, not as a replacement for one.
