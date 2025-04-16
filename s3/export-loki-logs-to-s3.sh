#!/bin/bash

# Configurable vars
LOKI_URL="http://a68e3484cc6ff4de4b97e97f46d6e2ca-1918663355.me-south-1.elb.amazonaws.com:3100"
S3_BUCKET="meryem-loki-logs"
APP_LABEL="haproxy"
TIME_RANGE="1h"
OUTPUT_DIR="/var/log/loki"
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
FILENAME="${APP_LABEL}-logs-${NOW}.json"
GZ_FILENAME="${FILENAME}.gz"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Export logs
echo "[INFO] Exporting logs for {app=\"$APP_LABEL\"} from last $TIME_RANGE..."
curl -s -G \
  --data-urlencode "query={app=\"$APP_LABEL\"}" \
  --data-urlencode "start=now-${TIME_RANGE}" \
  "${LOKI_URL}/loki/api/v1/query_range" \
  -o "${OUTPUT_DIR}/${FILENAME}"

# Check if export succeeded
if [[ $? -ne 0 || ! -s "${OUTPUT_DIR}/${FILENAME}" ]]; then
  echo "[ERROR] Failed to export logs from Loki"
  exit 1
fi

# Compress the log file
echo "[INFO] Compressing log file..."
gzip -f "${OUTPUT_DIR}/${FILENAME}"

# Upload to S3
echo "[INFO] Uploading compressed logs to S3: s3://${S3_BUCKET}/logs/${GZ_FILENAME}"
aws s3 cp "${OUTPUT_DIR}/${GZ_FILENAME}" "s3://${S3_BUCKET}/logs/${GZ_FILENAME}"

# Verify upload
if [[ $? -eq 0 ]]; then
  echo "[SUCCESS] Logs uploaded successfully: ${GZ_FILENAME}"
else
  echo "[ERROR] Failed to upload logs to S3."
  exit 1
fi
