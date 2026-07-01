# AKS module (stub)

Follows the same pattern as `../eks`: an `azurerm_kubernetes_cluster` resource with
a managed control plane (AKS Automatic or Standard — ADR-0006), a default node pool
sized via variables, and outputs exposing the kube_config for downstream use.

Not fleshed out in this reference repo to avoid duplicating near-identical Terraform
across three clouds — the EKS module is the canonical example; port the same shape
using `azurerm_kubernetes_cluster`.
