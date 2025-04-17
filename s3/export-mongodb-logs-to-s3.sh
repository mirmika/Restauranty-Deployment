#!/bin/bash

LOKI_URL="http://a68e3484cc6ff4de4b97e97f46d6e2ca-1918663355.me-south-1.elb.amazonaws.com:3100"
S3_BUCKET="meryem-loki-logs"
APP_LABEL="mongo"
OUTPUT_DIR="/var/log/loki"
NOW=$(date -u +"%Y-%m-%dT%H-%M-%SZ")
FILENAME="${APP_LABEL}-logs-${NOW}.json"
ZIP_FILENAME="${FILENAME}.zip"

START_TIME=$(date -u -d "1 hour ago" +%s%N)
END_TIME=$(date -u +%s%N)

mkdir -p "$OUTPUT_DIR"

echo "[INFO] Exporting logs for {app=\"$APP_LABEL\"} from last 1h..."
RESPONSE=$(curl -s -G \
  -H "Accept-Encoding: identity" \
  --data-urlencode "query={app=\"$APP_LABEL\"}" \
  --data-urlencode "start=${START_TIME}" \
  --data-urlencode "end=${END_TIME}" \
  "${LOKI_URL}/loki/api/v1/query_range")

echo "$RESPONSE" | jq . > "${OUTPUT_DIR}/${FILENAME}"

if [[ $? -ne 0 || ! -s "${OUTPUT_DIR}/${FILENAME}" || $(jq -e '.data.result | length == 0' "${OUTPUT_DIR}/${FILENAME}") == "true" ]]; then

  echo "[WARN] No logs exported or export failed."
  rm -f "${OUTPUT_DIR:?}/${FILENAME}"
  exit 0
fi

echo "[INFO] Compressing file to zip..."
zip -j "${OUTPUT_DIR}/${ZIP_FILENAME}" "${OUTPUT_DIR}/${FILENAME}"

echo "[INFO] Uploading zipped log to S3: s3://${S3_BUCKET}/logs/${ZIP_FILENAME}"
aws s3 cp "${OUTPUT_DIR}/${ZIP_FILENAME}" "s3://${S3_BUCKET}/logs/${ZIP_FILENAME}"

if [[ $? -eq 0 ]]; then
  echo "[SUCCESS] Logs uploaded successfully: ${ZIP_FILENAME}"
else
  echo "[ERROR] Failed to upload logs to S3."
  exit 1
fi
