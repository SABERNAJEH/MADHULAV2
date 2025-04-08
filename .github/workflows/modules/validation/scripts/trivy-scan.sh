#!/bin/bash
set -euo pipefail

TARGET_DIR=${1:-"."}
OUTPUT_DIR="results"
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
SCAN_DATE=$(date +%Y-%m-%d)

# Install Trivy if not exists
if ! command -v trivy &> /dev/null; then
  echo "Installing Trivy..."
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
fi

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Run scans
echo "Running Trivy scans on ${TARGET_DIR}..."

# 1. Scan Kubernetes manifests
trivy k8s --report summary --timeout 10m \
  --format json \
  --output "${OUTPUT_DIR}/trivy-k8s-${SCAN_DATE}.json" \
  "${TARGET_DIR}"/*.yaml

# 2. Scan container images (if any)
find "${TARGET_DIR}" -name "*.yaml" -exec grep -h "image:" {} \; | \
  awk '{print $2}' | sort | uniq | \
  while read -r image; do
    echo "Scanning image: ${image}"
    trivy image --security-checks vuln,config \
      --format json \
      --output "${OUTPUT_DIR}/trivy-image-$(echo "${image}" | tr '/' '-').json" \
      "${image}"
  done

# Generate consolidated report
jq -s '.[0].Results + .[1].Results' "${OUTPUT_DIR}"/trivy-*.json > "${OUTPUT_DIR}/trivy-final-report.json"

# Upload results as artifact
echo "SCAN_RESULTS=${OUTPUT_DIR}/trivy-final-report.json" >> $GITHUB_ENV

exit 0
