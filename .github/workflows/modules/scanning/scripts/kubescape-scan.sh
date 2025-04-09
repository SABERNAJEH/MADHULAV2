#!/bin/bash
set -euo pipefail

TARGET_DIR="${1:-.}"
OUTPUT_DIR="${2:-results}"
REPO_NAME=$(basename $(git rev-parse --show-toplevel))

echo "Running Kubescape scan on: ${TARGET_DIR}"

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Install Kubescape if not exists
if ! command -v kubescape &> /dev/null; then
    echo "Installing Kubescape..."
    curl -s https://raw.githubusercontent.com/kubescape/kubescape/master/install.sh | /bin/bash
    export PATH=$PATH:/home/runner/.kubescape/bin
fi

# Execute scan
kubescape scan "${TARGET_DIR}" \
    --format json \
    --output "${OUTPUT_DIR}/kubescape-scan.json" \
    --exceptions kubescape-exceptions.json

echo "Scan results saved to: ${OUTPUT_DIR}/kubescape-scan.json"
