#!/bin/sh

set -e  
set -x

if [ $# -ne 1 ]; then
    echo "Usage: $0 source-file" >&2
    exit 1
fi

SRC="$1"  

if [ ! -f "$SRC" ]; then
    echo "Source file '$SRC' not found" >&2
    exit 2
fi

OUTPUT=$(grep -E '&Output:\s*[[:alnum:][:space:]\._\-]+' "$SRC" | head -n1 | \
         sed -E 's/.*&Output:\s*([[:alnum:][:space:]\._\-]+).*/\1/' | xargs)

echo "OUTPUT='$OUTPUT'"

if [ -z "$OUTPUT" ]; then
    echo "No &Output: directive found in source file" >&2
    exit 3
fi

case "$SRC" in
    *.c)
        COMPILER="cc"
        COMPILE_CMD="\$COMPILER \$SRC -o \$OUTPUT"
        ;;
    *.cpp|*.cc)
        COMPILER="g++"
        COMPILE_CMD="\$COMPILER \$SRC -o \$OUTPUT"
        ;;
    *)
        echo "Unsupported file type" >&2
        exit 4
        ;;
esac

TMPDIR=$(mktemp -d)
ORIG_DIR="$(pwd)"
trap 'rm -rf "$TMPDIR"; exit' INT TERM EXIT

cp "$SRC" "$TMPDIR"

cd "$TMPDIR" || exit 5

eval "$COMPILE_CMD"

mv "$OUTPUT" "$ORIG_DIR" || {
    echo "Failed to move output file back to original directory" >&2
    exit 6
}

exit 0
