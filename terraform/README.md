# Terraform

`modules/eks` is the fleshed-out reference module. It provisions the control
plane + managed node group + IAM, and bakes in a security baseline:

- **Secrets envelope encryption** — a KMS key (auto-rotating; bring-your-own via
  `kms_key_arn`) encrypts Kubernetes Secrets at rest.
- **IMDSv2 required** — the node launch template enforces `http_tokens = required`
  with a hop limit of 1, blocking the pod→IMDS→node-role credential-theft path.
- **API endpoint access** — private access on; public access on but gated by
  `public_access_cidrs` (defaults to `0.0.0.0/0` for out-of-the-box reachability
  — **restrict it before real use**).
- **IRSA** — the cluster's OIDC issuer is registered as an IAM OIDC provider
  (exported as `oidc_provider_arn`); workload-specific roles are out of scope.

`modules/gke` and `modules/aks` are documented stubs following the same shape —
see their READMEs. `environments/example-prod` wires the EKS module together for
a single environment; it's a template, not a ready-to-apply stack (you need a
real VPC/subnets and your own remote backend for state — a commented S3 backend
stub is included in `main.tf`).

Provider lock files (`.terraform.lock.hcl`) are committed with multi-platform
hashes (`linux_amd64` for CI, `darwin_arm64` for local dev). Regenerate with
`terraform providers lock -platform=linux_amd64 -platform=darwin_arm64` when
bumping providers.
