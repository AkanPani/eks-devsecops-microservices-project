#!/usr/bin/env bash
set -euo pipefail

REGISTRY=""
TAG=""
LATEST_TAG="latest"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --registry) REGISTRY="$2"; shift 2 ;;
    --tag) TAG="$2"; shift 2 ;;
    --latest-tag) LATEST_TAG="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$REGISTRY" || -z "$TAG" ]]; then
  echo "Usage: $0 --registry <ecr-registry> --tag <image-tag> [--latest-tag <latest-tag>]"
  exit 1
fi

SERVICES=("product-service" "order-service")

for SERVICE in "${SERVICES[@]}"; do
  IMAGE_URI="${REGISTRY}/${SERVICE}:${TAG}"
  LATEST_URI="${REGISTRY}/${SERVICE}:${LATEST_TAG}"

  echo "Pushing ${IMAGE_URI}"
  docker push "${IMAGE_URI}"

  echo "Pushing ${LATEST_URI}"
  docker push "${LATEST_URI}"
done

echo "Docker push completed."
