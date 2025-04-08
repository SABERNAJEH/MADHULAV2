#!/bin/bash
TARGET=$1

mkdir -p results
kubescape scan "$TARGET" \
  --format json \
  --output results/kubescape-results.json \
  --exceptions kubescape-exceptions.json

exit 0
