# GKE module (stub)

Follows the same pattern as `../eks`: a `google_container_cluster` resource with a
managed control plane (Standard or Autopilot mode — ADR-0006), a node pool sized via
variables, and outputs exposing the endpoint and CA data for kubeconfig generation.

Not fleshed out in this reference repo to avoid duplicating near-identical Terraform
across three clouds — the EKS module is the canonical example; port the same shape
using `google_container_cluster` + `google_container_node_pool`.
