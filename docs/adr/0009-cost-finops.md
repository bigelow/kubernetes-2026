# ADR-0009: Cost — Requests/Limits Discipline + Per-Tenant Allocation

**Status:** Accepted

## Context
Kubernetes makes it trivial to request infrastructure and easy to over-provision. CNCF's FinOps
microsurvey found Kubernetes drove cloud spend up for roughly half of surveyed organizations. Cost
visibility does not happen by default — it has to be designed in.

## Decision
- Every workload sets CPU/memory **requests and limits**; ResourceQuota enforced per tenant namespace.
- Cost data is joined from cloud billing + Kubernetes resource metrics + namespace/team labels, not
  billing data alone.
- Right-sizing (requests vs actual usage) is a recurring review, not a one-time setup step.

## Consequences
- Requires labeling discipline across every namespace from day one — retrofitting is expensive.
- Enables per-team/per-service cost allocation, which is a prerequisite for any real chargeback model.

## References
- https://www.cncf.io/reports/cloud-native-and-kubernetes-finops-microsurvey/
- https://www.finops.org/wg/calculating-container-costs/
