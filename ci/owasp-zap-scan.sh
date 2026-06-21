#!/usr/bin/env bash
set -euo pipefail

TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 --target <app-url>"
  exit 1
fi

mkdir -p reports/zap
cp zap/zap-baseline.conf reports/zap/zap-baseline.conf

echo "Running OWASP ZAP baseline scan for ${TARGET}"

docker run --rm \
  -v "$(pwd)/reports/zap:/zap/wrk:rw" \
  ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py \
  -t "${TARGET}" \
  -c /zap/wrk/zap-baseline.conf \
  -r zap-report.html \
  -J zap-report.json \
  -x zap-report.xml || ZAP_EXIT_CODE=$?

ZAP_EXIT_CODE="${ZAP_EXIT_CODE:-0}"

# ZAP baseline:
# 0 = pass, 1 = fail alerts, 2 = warn alerts, 3 = scan error.
# For dev, allow warnings but fail on actual fail/error.
if [[ "${ZAP_EXIT_CODE}" == "1" || "${ZAP_EXIT_CODE}" == "3" ]]; then
  echo "OWASP ZAP failed with exit code ${ZAP_EXIT_CODE}"
  exit "${ZAP_EXIT_CODE}"
fi

echo "OWASP ZAP completed with exit code ${ZAP_EXIT_CODE}"
