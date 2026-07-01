# ADR-0001: Container Runtime — containerd/CRI-O over Docker Engine

**Status:** Accepted

## Context
Docker Engine was the default Kubernetes runtime for years via dockershim. Dockershim was removed
in Kubernetes v1.24 (April 2022). Clusters now require a CRI-compliant runtime directly.

## Decision
Use **containerd** as the default node runtime (CRI-O as the alternative where SELinux/OpenShift
alignment matters). Do not depend on Docker Engine anywhere in the cluster runtime path.

## Consequences
- Developer workflows (image builds, `docker` CLI habits) are unaffected — this is a node-level change.
- Any tooling that shells out to the Docker socket on nodes (some older monitoring/security agents)
  needs to be replaced with CRI-compatible equivalents.
- Simpler node image, fewer moving parts, matches what every major managed offering (EKS, GKE, AKS)
  ships by default.

## References
- https://kubernetes.io/blog/2022/02/17/dockershim-faq/
