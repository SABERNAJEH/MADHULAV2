#!/bin/bash

echo "Installing Trivy..."
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

echo "Running Trivy scan on Kubernetes manifests..."
trivy config --security-checks config . -f json -o trivy-results.json

# Merge scan results
jq -s '.[0] * .[1]' scan-results.json trivy-results.json > combined-scan-results.json
mv combined-scan-results.json scan-results.json

# Check if scan was successful
if [ $? -ne 0 ]; then
    echo "Trivy scan failed"
    exit 1
fi

echo "Trivy scan completed successfully"
