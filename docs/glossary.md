# Glossary

- **ADR** — Architecture Decision Record. A short doc capturing one decision, its
  context, and its consequences. See `docs/adr/`.
- **CNI** — Container Network Interface; the pluggable networking layer Kubernetes delegates to.
- **CRI** — Container Runtime Interface; how Kubernetes talks to node runtimes (containerd, CRI-O).
- **DRA** — Dynamic Resource Allocation; GA in v1.34, used for GPU/accelerator scheduling.
- **Gateway API** — successor traffic-routing model to Ingress.
- **vCluster** — a virtual Kubernetes control plane running inside a namespace of a host cluster,
  used here for the hard multi-tenancy isolation tier.
