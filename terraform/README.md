# Terraform

`modules/eks` is the fleshed-out reference module (control plane + node group + IAM).
`modules/gke` and `modules/aks` are documented stubs following the same shape — see
their READMEs. `environments/example-prod` wires the EKS module together for a single
environment; it's a template, not a ready-to-apply stack (you need a real VPC/subnets
and your own backend config for state).
