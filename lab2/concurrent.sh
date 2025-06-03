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
  tmp_name=$( (
    flock 200

    i=1
    while [ "$i" -le 9999 ]; do
      name=$(printf "%03d" "$i")
      if [ ! -e "$SHARED_DIR/$name" ]; then
        break
      fi
      i=$((i + 1))
    done

    if [ -z "$name" ]; then
      echo ""
      exit 1
    fi

    echo "$CONTAINER_ID:$FILE_COUNTER" > "$SHARED_DIR/$name"
    echo "$name"
    exit 0

  ) 200>"$LOCK_FILE" )

  name_exit_code="$?"
  name="$tmp_name"

  if [ "$name_exit_code" -ne 0 ]; then
    echo "No available filename found, retrying..."
    sleep 5
    continue
  fi

  echo "[DEBUG] Created file $SHARED_DIR/$name with content: $CONTAINER_ID:$FILE_COUNTER"

  sleep 1

  expected_content="$CONTAINER_ID:$FILE_COUNTER"
  current_content="$(cat "$SHARED_DIR/$name" 2>/dev/null)"

  if [ "$current_content" = "$expected_content" ]; then
    rm -f "$SHARED_DIR/$name" && \
      echo "[DEBUG] Removed file: $SHARED_DIR/$name"
  else
    echo "[WARN] File changed or reused by another container — not deleting: $SHARED_DIR/$name"
  fi

  FILE_COUNTER=$((FILE_COUNTER + 1))

  sleep 1
done