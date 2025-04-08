#!/bin/bash
godgo validate ./kubernetes-goat/ \
  --strict \
  --output=godgo-report.json

if [ $? -ne 0 ]; then
  echo "Validation failed"
  exit 1
fi
