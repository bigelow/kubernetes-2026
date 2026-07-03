#!/usr/bin/env bash
# One-command local bring-up: k3d cluster + reference core manifests +
# observability spine. Idempotent — safe to re-run. See local/README.md.
set -euo pipefail
cd "$(dirname "$0")/.."

CLUSTER=k2026
IMAGE_TAG=registry.internal.example.com/demo-app:0.1.0

# --- 1. Cluster -------------------------------------------------------------
if ! k3d cluster list "$CLUSTER" >/dev/null 2>&1; then
  k3d cluster create --config local/cluster.yaml
fi

# LOCAL DELTA: exempt k3s system workloads (traefik, coredns, ...) from the
# image-registry policy — their images aren't from the approved registry.
kubectl label ns kube-system tier=platform-system --overwrite

# --- 2. Reference core: namespaces, admission policies, OTel collector ------
kubectl kustomize --load-restrictor LoadRestrictionsNone local/kustomize/core \
  | kubectl apply -f -

# --- 3. Demo workload (traces/metrics/logs source) ---------------------------
docker build -t "$IMAGE_TAG" local/demo-app
k3d image import -m direct -c "$CLUSTER" "$IMAGE_TAG"
kubectl kustomize local/kustomize/demo | kubectl apply -f -

# --- 4. Observability spine (pinned charts) ----------------------------------
helm repo add grafana https://grafana.github.io/helm-charts >/dev/null
helm repo update grafana >/dev/null

helm upgrade --install loki    grafana/loki              --version 7.0.0   \
  -n platform-observability -f local/helm/loki-values.yaml    --wait --timeout 10m &
helm upgrade --install tempo   grafana/tempo             --version 1.24.4  \
  -n platform-observability -f local/helm/tempo-values.yaml   --wait --timeout 10m &
helm upgrade --install mimir   grafana/mimir-distributed --version 6.1.0   \
  -n platform-observability -f local/helm/mimir-values.yaml   --wait --timeout 10m &
helm upgrade --install alloy   grafana/alloy             --version 1.10.0  \
  -n platform-observability -f local/helm/alloy-values.yaml   --wait --timeout 10m &
helm upgrade --install grafana grafana/grafana           --version 10.5.15 \
  -n platform-observability -f local/helm/grafana-values.yaml --wait --timeout 10m &
for pid in $(jobs -p); do wait "$pid"; done   # propagate any install failure

# --- 5. Dashboards as code ----------------------------------------------------
kubectl -n platform-observability create configmap grafana-dashboards \
  --from-file=local/dashboards/ --dry-run=client -o yaml \
  | kubectl label -f - --local --dry-run=client -o yaml grafana_dashboard=1 \
  | kubectl apply -f -

# --- 6. Wait + smoke ----------------------------------------------------------
kubectl -n team-demo rollout status deploy/demo-app --timeout=180s
kubectl -n platform-observability rollout status deploy/otel-collector --timeout=180s

echo
echo "Cluster up. Demo app:  http://demo.localhost:8080/api/orders"
echo "Grafana:               http://grafana.localhost:8080  (admin / k2026-local)"
