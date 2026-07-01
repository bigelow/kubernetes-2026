# ADR-0002: Networking — Cilium (eBPF) as Default CNI

**Status:** Accepted

## Context
Kubernetes defines the networking model but delegates enforcement to a CNI plugin. Traditional
iptables-based CNIs (Flannel-era) work but lack modern observability and L7 policy enforcement.
Cilium is a CNCF-graduated (2023), eBPF-based project covering networking, security, and observability.

## Decision
Default to **Cilium** for new clusters. Keep the CNI layer pluggable — this is a default, not a
hard dependency baked into other decisions.

## Consequences
- Gains: kernel-level policy enforcement, L3–L7 network policies, built-in observability (Hubble),
  better performance at scale than iptables-based chains.
- Cost: more operational surface than a minimal CNI; team needs eBPF-aware troubleshooting skills.
- Not a universal mandate — simpler clusters (dev/sandbox) may reasonably stay on a lighter CNI.

## References
- https://www.cncf.io/announcements/2023/10/11/cloud-native-computing-foundation-announces-cilium-graduation/
