#!/usr/bin/env bash
set -euo pipefail

# scripts/bootstrap-all.sh
# Automated bootstrap: creates Kubernetes namespace, secrets (from env or files),
# applies PVC/storage, and installs Helm charts for apz-node, apz-indexer, apz-api.
#
# Usage:
#   export KUBECONFIG=~/.kube/config
#   export NAMESPACE=apz
#   export REGISTRY=ghcr.io/your-org
#   export NODE_IMAGE_TAG=latest
#   export INDEXER_IMAGE_TAG=latest
#   export API_IMAGE_TAG=latest
#   # Provide DB/Redis secrets or use files below
#   ./scripts/bootstrap-all.sh

NAMESPACE="${NAMESPACE:-apz}"
REGISTRY="${REGISTRY:-ghcr.io/your-org}"
NODE_IMAGE_TAG="${NODE_IMAGE_TAG:-latest}"
INDEXER_IMAGE_TAG="${INDEXER_IMAGE_TAG:-latest}"
API_IMAGE_TAG="${API_IMAGE_TAG:-latest}"

# Secret inputs (either env or files)
DB_URL="${DB_URL:-postgres://postgres:password@apz-postgres:5432/apz}"
REDIS_URL="${REDIS_URL:-redis://apz-redis:6379}"
JWT_SECRET="${JWT_SECRET:-$(head -c 32 /dev/urandom | base64)}"

# Private key files for node (optional). If not present, chart secret will be empty placeholders.
NODE_PRIV_KEY_FILE="${NODE_PRIV_KEY_FILE:-./priv/priv_validator.json}"
NODE_KEY_FILE="${NODE_KEY_FILE:-./priv/node_key.json}"

echo "Bootstrap APZ infra into namespace: $NAMESPACE"
echo "Registry prefix: $REGISTRY"

# Check kubectl and helm
command -v kubectl >/dev/null 2>&1 || { echo "kubectl missing"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "helm missing"; exit 1; }

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Create docker-registry secret for pulling private images if needed (OPTIONAL)
if [ -n "${REGISTRY_USER:-}" ] && [ -n "${REGISTRY_PASS:-}" ]; then
  kubectl create secret docker-registry apz-registry-secret \
    --docker-server="${REGISTRY%%/*}" \
    --docker-username="$REGISTRY_USER" \
    --docker-password="$REGISTRY_PASS" \
    -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
  echo "Created image pull secret apz-registry-secret"
fi

# Create DB/Redis/JWT secrets for apz-api and apz-indexer
kubectl create secret generic apz-api-secrets \
  --from-literal=DATABASE_URL="$DB_URL" \
  --from-literal=REDIS_URL="$REDIS_URL" \
  --from-literal=JWT_SECRET="$JWT_SECRET" \
  -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic apz-indexer-secrets \
  --from-literal=DATABASE_URL="$DB_URL" \
  -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Create apz-node secret for private keys if files exist
if [ -f "$NODE_PRIV_KEY_FILE" ] || [ -f "$NODE_KEY_FILE" ]; then
  kubectl create secret generic apz-node-secrets \
    --from-file=PRIV_VALIDATOR_KEY="$NODE_PRIV_KEY_FILE" \
    --from-file=NODE_KEY="$NODE_KEY_FILE" \
    -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
  echo "Created apz-node-secrets from files"
else
  # create empty placeholders to satisfy helm templates
  kubectl create secret generic apz-node-secrets \
    --from-literal=PRIV_VALIDATOR_KEY="" \
    --from-literal=NODE_KEY="" \
    -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
  echo "Created apz-node-secrets with placeholders (no key files found)"
fi

# Create any persistent volume claims if your cluster needs them created via kubectl
# (Assumes dynamic provisioning available; otherwise create PV manually)
echo "Ensuring storage class is available or PVC will request dynamic PVs"

# Install charts with image overrides
echo "Installing apz-node chart..."
helm upgrade --install apz-node infra/helm/node \
  -n "$NAMESPACE" \
  --set image.repository="${REGISTRY}/apz-node" \
  --set image.tag="${NODE_IMAGE_TAG}" \
  --wait

echo "Installing apz-indexer chart..."
helm upgrade --install apz-indexer infra/helm/indexer \
  -n "$NAMESPACE" \
  --set image.repository="${REGISTRY}/apz-indexer" \
  --set image.tag="${INDEXER_IMAGE_TAG}" \
  --wait

echo "Installing apz-api chart..."
helm upgrade --install apz-api infra/helm/api \
  -n "$NAMESPACE" \
  --set image.repository="${REGISTRY}/apz-api" \
  --set image.tag="${API_IMAGE_TAG}" \
  --wait

echo "All charts installed. Waiting for pods to be ready..."
kubectl rollout status deployment/apz-api -n "$NAMESPACE" --timeout=120s || true
kubectl rollout status deployment/apz-indexer -n "$NAMESPACE" --timeout=120s || true
kubectl rollout status deployment/apz-node -n "$NAMESPACE" --timeout=120s || true

echo "Bootstrap complete. Check pods:"
kubectl get pods -n "$NAMESPACE"
