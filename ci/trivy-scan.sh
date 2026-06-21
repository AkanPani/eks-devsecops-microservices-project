#!/usr/bin/env bash
set -euo pipefail

REGISTRY=""
TAG=""
SEVERITY="${TRIVY_SEVERITY:-HIGH,CRITICAL}"
EXIT_CODE="${TRIVY_EXIT_CODE:-1}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --registry) REGISTRY="$2"; shift 2 ;;
    --tag) TAG="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$REGISTRY" || -z "$TAG" ]]; then
  echo "Usage: $0 --registry <ecr-registry> --tag <image-tag>"
  exit 1
fi

mkdir -p reports/trivy
SERVICES=("product-service" "order-service")

for SERVICE in "${SERVICES[@]}"; do
  IMAGE_URI="${REGISTRY}/${SERVICE}:${TAG}"

  echo "Running Trivy scan for ${IMAGE_URI}"

  trivy image --no-progress --severity "${SEVERITY}" \
    --format table \
    --output "reports/trivy/${SERVICE}-trivy.txt" \
    "${IMAGE_URI}"

  trivy image --no-progress --severity "${SEVERITY}" \
    --format json \
    --output "reports/trivy/${SERVICE}-trivy.json" \
    "${IMAGE_URI}"

  trivy image --no-progress --severity "${SEVERITY}" \
    --exit-code "${EXIT_CODE}" \
    "${IMAGE_URI}"
done

echo "Trivy scan completed."
