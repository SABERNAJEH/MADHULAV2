#!/bin/bash
set -euo pipefail

DEPLOY_DIR="deployed-resources"
SCAN_DIR="scan-results"
KUBE_NAMESPACE="k8s-goat-$(date +%s)"

# Create directories
mkdir -p "${DEPLOY_DIR}" "${SCAN_DIR}"

# Install kubectl if not exists
if ! command -v kubectl &> /dev/null; then
  echo "Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
fi

# Deploy to test namespace
echo "Deploying Kubernetes Goat resources..."
kubectl create namespace "${KUBE_NAMESPACE}"
kubectl apply -f kubernetes-goat/ -n "${KUBE_NAMESPACE}" --dry-run=client -o yaml > "${DEPLOY_DIR}/deployed-resources.yaml"

# Wait for deployments
sleep 30  # Wait for resources to initialize

# Run post-deployment scans
echo "Running post-deployment scans..."

# 1. Scan running cluster
trivy k8s --report summary cluster \
  --format json \
  --output "${SCAN_DIR}/cluster-scan.json" \
  --namespace "${KUBE_NAMESPACE}"

# 2. Scan network policies
kubectl get netpol -n "${KUBE_NAMESPACE}" -o yaml > "${SCAN_DIR}/network-policies.yaml"
kubesec scan "${SCAN_DIR}/network-policies.yaml" > "${SCAN_DIR}/kubesec-report.json"

# Cleanup
kubectl delete namespace "${KUBE_NAMESPACE}"

# Generate final report
jq -n \
  --arg date "$(date)" \
  --arg namespace "${KUBE_NAMESPACE}" \
  --slurpfile cluster "${SCAN_DIR}/cluster-scan.json" \
  --slurpfile kubesec "${SCAN_DIR}/kubesec-report.json" \
  '{
    timestamp: $date,
    namespace: $namespace,
    clusterScan: $cluster[0],
    kubesecResults: $kubesec[0]
  }' > "${SCAN_DIR}/final-deploy-scan.json"

echo "DEPLOY_SCAN_RESULTS=${SCAN_DIR}/final-deploy-scan.json" >> $GITHUB_ENV
