#!/usr/bin/env bash
set -euo pipefail

REGISTRY=""
TAG=""

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

if [[ -z "${PRISMA_CONSOLE_URL:-}" || -z "${PRISMA_ACCESS_KEY:-}" || -z "${PRISMA_SECRET_KEY:-}" ]]; then
  echo "Prisma/Twistlock credentials are missing."
  echo "Required env vars: PRISMA_CONSOLE_URL, PRISMA_ACCESS_KEY, PRISMA_SECRET_KEY"
  exit 1
fi

if ! command -v twistcli >/dev/null 2>&1; then
  echo "twistcli not found in PATH. Install twistcli on Jenkins agent."
  exit 1
fi

mkdir -p reports/twistlock
SERVICES=("product-service" "order-service")

for SERVICE in "${SERVICES[@]}"; do
  IMAGE_URI="${REGISTRY}/${SERVICE}:${TAG}"

  echo "Running Prisma/Twistlock scan for ${IMAGE_URI}"

  twistcli images scan \
    --address "${PRISMA_CONSOLE_URL}" \
    --user "${PRISMA_ACCESS_KEY}" \
    --password "${PRISMA_SECRET_KEY}" \
    --details \
    --output-file "reports/twistlock/${SERVICE}-twistlock.json" \
    "${IMAGE_URI}"
done

echo "Twistlock / Prisma scan completed."
