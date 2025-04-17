#!/bin/bash

# Configurable vars
LOKI_URL="http://a68e3484cc6ff4de4b97e97f46d6e2ca-1918663355.me-south-1.elb.amazonaws.com:3100"
S3_BUCKET="meryem-loki-logs"
APP_LABEL="haproxy"
OUTPUT_DIR="/var/log/loki"
NOW=$(date -u +"%Y-%m-%dT%H-%M-%SZ")
FILENAME="${APP_LABEL}-logs-${NOW}.json"
TXT_FILENAME="${APP_LABEL}-logs-${NOW}-readable.txt"
ZIP_FILENAME="${APP_LABEL}-logs-${NOW}.zip"

# Timestamps for last 1 hour
START_TIME=$(date -u -d "1 hour ago" +%s%N)
END_TIME=$(date -u +%s%N)

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Export logs
echo "[INFO] Exporting logs for {app=\"$APP_LABEL\"} from last 1h..."
curl -s -G \
  -H "Accept-Encoding: identity" \
  --data-urlencode "query={app=\"$APP_LABEL\"}" \
  --data-urlencode "start=${START_TIME}" \
  --data-urlencode "end=${END_TIME}" \
  "${LOKI_URL}/loki/api/v1/query_range" \
  -o "${OUTPUT_DIR}/${FILENAME}"

# Check if export succeeded
if [[ $? -ne 0 || ! -s "${OUTPUT_DIR}/${FILENAME}" || $(jq -r '.data.result | length' < "${OUTPUT_DIR}/${FILENAME}") -eq 0 ]]; then
  echo "[WARN] No logs exported or export failed."
  rm -f "${OUTPUT_DIR:?}/${FILENAME}"
  exit 0
fi

# Format readable version
echo "[INFO] Formatting readable version..."
jq -r '.data.result[].values[] | @tsv' "${OUTPUT_DIR}/${FILENAME}" | while IFS=$'\t' read -r ts msg; do
  ts_readable=$(date -d "@$((${ts%% *} / 1000000000))" "+%Y-%m-%d %H:%M:%S")
  echo "$ts_readable $msg"
done > "${OUTPUT_DIR}/${TXT_FILENAME}"

# Create zip archive
zip -j "${OUTPUT_DIR}/${ZIP_FILENAME}" "${OUTPUT_DIR}/${TXT_FILENAME}" > /dev/null

# Upload to S3
echo "[INFO] Uploading zipped log to S3: s3://${S3_BUCKET}/logs/${ZIP_FILENAME}"
aws s3 cp "${OUTPUT_DIR}/${ZIP_FILENAME}" "s3://${S3_BUCKET}/logs/${ZIP_FILENAME}"

# Verify upload
if [[ $? -eq 0 ]]; then
  echo "[SUCCESS] Logs uploaded successfully: ${ZIP_FILENAME}"
else
  echo "[ERROR] Failed to upload logs to S3."
  exit 1
fi
