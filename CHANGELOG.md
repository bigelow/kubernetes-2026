# Changelog

Dated entries, newest first. Every entry lists each file touched and why, and
states plainly what was and was not re-verified. "Verified" means run against a
real API server of the stated version in this repo's own test loop, nothing less.

## 2026-10-10 — resource-defaults MAP fix; trivy green on `main`

Two commits on `main`, found and fixed while re-verifying the v1.37 bump.

- `security-policy/mutatingadmissionpolicy-resource-defaults.yaml` — the
  expression returned the whole container object for an already-satisfied
  container; an ApplyConfiguration may not carry atomic fields (`command`,
  `args`, `capabilities.drop`), and with `reinvocationPolicy: IfNeeded` the
  second pass saw the container it had just defaulted, so any such Pod was
  denied — including the repo's own otel-collector Deployment and the
  ai-scheduling example Pod. A container with requests above the fixed
  default limits and no limits also ended up invalid (requests > limits).
  Fix: emit only the missing cpu/memory keys as `?`-optional fields; a
  satisfied container yields just `{name: c.name}`. `IfNeeded` stays. The
  `main` commit (7424220) also copied a missing limit from the request; this
  PR drops that branch after re-reading ADR-0009 (it requires requests *and*
  limits to be set, not to be equal): a requests-only container now stays
  requests-only (Burstable QoS preserved). A missing request still copies
  the limit, which is the defaulting the API server applies by itself to a
  limits-only Pod (demonstrated in the suite with no policy installed). Fixed
  defaults apply only to a key absent from both.
  **Verified on kind v1.37.0** (kindest/node:v1.37.0, kind v0.33.0, kubectl
  v1.37.1): container with `command` and no resources (defaults filled);
  container with `capabilities.drop` and resources set (untouched); the
  ai-scheduling example Pod (both policies live, no exemption) and the
  otel-collector Deployment with the policy live; requests-only (left
  alone) / limits-only (requests := limits) / cpu-only partial shapes; a
  later MAP adding a container (reinvocation defaults it); plus the original
  claims. Full 5d suite and focused suite outputs are in the PR.
- `local/kustomize/core/patch-map-resource-defaults.yaml` removed and its
  `kustomization.yaml` entry dropped — the local overlay now applies the
  reference policy unmodified (rendered expression identical). `local/README.md`
  updated; the k3d stack itself was not re-run.
- `security-policy/README.md` — bullet now says what the policy does
  (fills in only the missing keys) and carries the 2026-10-10 claim.
- `.trivyignore` → `.trivyignore.yaml`, `Makefile`, `.github/workflows/validate.yml`,
  `README.md`, `local/kustomize/core/patch-otel-collector-deployment.yaml` +
  `kustomization.yaml` — `make validate` failed on `main` with 18 trivy
  findings, all from the local-stack commit eda488b. 13 were a strategic-merge
  patch fragment scanned as a whole Deployment: rewritten as a JSON6902 op
  list (rendered overlay byte-identical, no suppression). 4 are the demo
  app's deliberate `resources` omission (live MAP test): suppressed for that
  one file only, via trivy's YAML ignore format with path scoping and a
  written statement. 1 is the Dockerfile HEALTHCHECK rule: suppressed,
  path-scoped, because Kubernetes ignores the instruction and the
  readinessProbe is the real check. Every pre-existing entry carried over
  with its rationale. trivy only auto-loads the plain format, so lint and CI
  pass `--ignorefile .trivyignore.yaml`. `make validate` exits 0.

## 2026-10-09 — Kubernetes v1.36 → v1.37

Baseline moved from v1.36 to v1.37 (released 2026-08-26, codename Garhwal).
Sources: kubernetes.io docs, the v1.37 release blog, and `CHANGELOG-1.37.md`.
No manifest in the repo needed a semantic change: v1.37 removes only the alpha
`scheduling.k8s.io/v1alpha2` API, and the kubernetes.io deprecation guide has
no v1.37 entry. Every API version the repo uses (`admissionregistration.k8s.io/v1`,
`resource.k8s.io/v1`, `gateway.networking.k8s.io/v1`, `apps/v1`, `batch/v1`,
`networking.k8s.io/v1`, `rbac.authorization.k8s.io/v1`, core `v1`) is still served.

### What v1.37 changed for this repo (per ADR / folder)

| Area | v1.37 change | Result |
|---|---|---|
| ADR-0001 runtime | `SELinuxMount` GA (only affects SELinux-enabled nodes; no manifest sets `seLinuxOptions`) | no change |
| ADR-0002 CNI | nothing relevant (kube-proxy ipvs deprecation warning; nftables still not default) | no change |
| ADR-0003 Gateway API | nothing in core; Gateway API CRDs are external (v1.6.3 used for dry-run) | no change |
| ADR-0004 stateful | StatefulSet `Recreate` strategy (alpha), `MaxUnavailableStatefulSet` on by default; example sets neither | no change |
| ADR-0005 tenancy | nothing relevant | no change |
| ADR-0006 managed | EKS lists 1.37 on standard support (EKS release 2026-10-01) | Terraform default bumped |
| ADR-0007 admission | manifest-based admission control graduated to **Beta** (enabled by default); `.static.k8s.io` names reserved; MAP/VAP `v1` schemas unchanged (no new required or deprecated fields) | doc-only note |
| ADR-0008 DRA | `ResourceClaim.status.devices`, DRA device taints, DRA extended resources all GA; Workload/PodGroup gang scheduling **Beta** (`scheduling.k8s.io/v1beta1`, gate off by default) | doc-only note; no manifest change (status is driver-written) |
| ADR-0009 cost | `metrics.k8s.io` promoted to `v1` without changes; the exporter Role's RBAC rule is version-agnostic | no change |
| HPA scale-to-zero (Beta), KYAML (GA) | no existing doc touches either | not mentioned |

### Files touched

- `README.md` — "current as of" line → October 2026 / v1.37; kubeconform note
  reworded from a v1.37 baseline (MAP GA in v1.36 is still true; the catalog
  has now caught up, the flag stays as a guard).
- `.github/workflows/validate.yml` — kubeconform `-kubernetes-version 1.37.0`;
  comment on `-ignore-missing-schemas` updated to match.
- `mise.toml` — kubectl pin 1.36.2 → 1.37.1 (the client used for the
  verification below; within skew of both the v1.37 kind cluster and the
  v1.36.2 local k3d cluster).
- `terraform/modules/eks/variables.tf`, `terraform/environments/example-prod/variables.tf`
  — `kubernetes_version` default 1.36 → 1.37 with the EKS support-list check
  re-dated.
- `docs/adr/0007-security-admission-policy.md` — Context/Consequences note on
  manifest-based admission control (Beta) and the reserved name suffix; refs.
- `docs/adr/0008-ai-gpu-scheduling.md` — Consequences note on the three DRA GA
  graduations and the gang-scheduling Beta scope note; refs.
- `security-policy/README.md`, `ai-scheduling/README.md` — matching scope notes.
- `cost-allocation/mutatingadmissionpolicy-cost-label.yaml` — VERIFIED header
  comment re-dated to v1.37.0 (comment-only; expression untouched). The
  resource-defaults policy's header is owned by the 2026-10-10 fix above.
- `ai-scheduling/dra-deviceclass-resourceclaim.yaml` — example image
  `inference-worker:1.0` → `registry.internal.example.com/inference-worker:1.0`,
  the internal registry the image-registry VAP already allows, so the example
  applies clean with both policies live (verified; the allowlist is unchanged).
- `security-policy/README.md`, `cost-allocation/README.md`,
  `docs/blog/kubernetes-2026.md` — "verified against v1.36" → v1.37 for the
  policies actually re-run (see below). The published companion post now needs
  the same wording change; that lives outside this repo.
- `local/README.md`, `local/cluster.yaml` — comment/prose only: the k3d stack
  stays on k3s v1.36.2 and now says so honestly (see "Not re-verified").
- `CHANGELOG.md` — this file (new).

### Pinned verification image

`kindest/node:v1.37.0@sha256:a1ed56cfb0e7b93589bdf97c8cd566405a265939e3620fc4f5de89adff580ae5`
— the newest published v1.37.x node image on Docker Hub as of 2026-10-09 (there
is no v1.37.1 node image yet, although upstream v1.37.1 exists), as shipped by
kind v0.33.0. Confirmed present before pinning.

### Re-verified on v1.37.0 (kind v0.33.0, kubectl v1.37.1, Gateway API CRDs v1.6.3)

- `kubectl apply --dry-run=server` over all 11 manifest files in the platform
  folders: 11/11 accepted.
- `restrict-image-registries` VAP: denies `nginx:latest` and an unapproved
  initContainer image with the policy message; admits `gcr.io/distroless/*` and
  `registry.internal.example.com/*`; admits anything in a `tier=platform-system`
  namespace (binding exemption).
- `default-resource-requests` MAP (as fixed on 2026-10-10): injects
  `100m/128Mi` + `500m/512Mi` into a container and an initContainer that omit
  `resources`; leaves pre-set requests/limits untouched; admits containers
  carrying atomic fields (`command`, `capabilities.drop`) with or without
  resources under `IfNeeded` reinvocation.
- `inject-cost-label` MAP: new namespace without labels gets
  `cost-center=unassigned`; a pre-set `cost-center` is kept and an unrelated
  label survives the SSA merge.
- `ai-scheduling/dra-deviceclass-resourceclaim.yaml` applied for real:
  DeviceClass, ResourceClaimTemplate and Pod accepted; the controller generated
  a ResourceClaim from the template (Pod stays Pending — no DRA driver in kind).
- `make validate` sub-steps, `tflint`, `kubeconform` (CI flags, 1.37.0: 25/25
  valid, 0 skipped), `terraform fmt -check`, `terraform validate` for
  `modules/eks` and `environments/example-prod`: all pass.

### Not re-verified

- `local/` k3d stack (`local/cluster.yaml`, `local/up.sh`, `local/README.md`
  "Verified live" section) — still pinned to `rancher/k3s:v1.36.2-k3s1` and its
  claims still say v1.36.2. A `rancher/k3s:v1.37.1-k3s1` image exists, but k3d
  and helm were not available in the verification environment and the full
  bring-up (five Helm charts) was not re-run. Bump the pin only after
  `mise run local-up` has been run on it.
- `terraform plan`/`apply` against EKS 1.37 (needs real AWS credentials;
  the default is based on the EKS support list, not an apply).
- The live Gateway API controller path (`traffic-management/`) — only
  server-side dry-run against the v1.6.3 CRDs, as before.

### Observed, not changed

- The verification pass found two pre-existing problems — the
  resource-defaults MAP denying Pods with atomic fields, and `make lint`
  failing on `main` from the local-stack commits — both fixed in the
  2026-10-10 entry above.
- kubernetes.io's DRA concept page banner reads "Stable since Kubernetes v1.35"
  while the feature-gate table and the v1.34 release blog say the
  `DynamicResourceAllocation` gate went Stable in 1.34 (locked in 1.35). The
  repo's "GA in v1.34" wording is left as is.
