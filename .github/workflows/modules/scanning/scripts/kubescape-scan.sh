#!/bin/bash

echo "Installing Kubescape..."
curl -s https://raw.githubusercontent.com/kubescape/kubescape/master/install.sh | /bin/bash

echo "Running Kubescape scan on Kubernetes manifests..."
kubescape scan *.yaml --format json --output scan-results.json

# Check if scan was successful
if [ $? -ne 0 ]; then
    echo "Kubescape scan failed"
    exit 1
fi

echo "Kubescape scan completed successfully"
