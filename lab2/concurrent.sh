#!/bin/sh
set -e

SHARED_DIR="/shared"
LOCK_FILE="$SHARED_DIR/.lock"

CONTAINER_ID="${CONTAINER_ID:-$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c8)}"
FILE_COUNTER=1

mkdir -p "$SHARED_DIR"
touch "$LOCK_FILE"

echo "[INFO] Starting script for container ID: $CONTAINER_ID"

while true; do
  (
    flock 200

    i=1
    while [ "$i" -le 9999 ]; do
      name=$(printf "%03d" "$i")
      if [ ! -e "$SHARED_DIR/$name" ]; then
        break
      fi
      i=$((i + 1))
    done

    if [ "$i" -gt 9999 ]; then
      echo ""
      exit 1
    fi

    echo "$CONTAINER_ID:$FILE_COUNTER" > "$SHARED_DIR/$name"
    echo "[DEBUG] Created file $SHARED_DIR/$name with content: $CONTAINER_ID:$FILE_COUNTER"

    sleep 1

    rm -f "$SHARED_DIR/$name" && \
      echo "[DEBUG] Removed file: $SHARED_DIR/$name" || \
      echo "[ERROR] Failed to remove file: $SHARED_DIR/$name"

    echo "$name"
    exit 0

  ) 200>"$LOCK_FILE"

  name="$?"

  if [ "$name" -ne 0 ]; then
    echo "No available filename found or failed to acquire lock, retrying..."
    sleep 5
    continue
  fi

  FILE_COUNTER=$((FILE_COUNTER + 1))

  sleep 1
done