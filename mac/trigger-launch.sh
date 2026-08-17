#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED_DIR="${VM_LAUNCH_SHARED_DIR:-$ROOT_DIR/shared}"
PROCESSED_DIR="$SHARED_DIR/processed"

mkdir -p "$SHARED_DIR" "$PROCESSED_DIR"

LABEL="manual-launch"
if [[ "${1:-}" == "--label" && -n "${2:-}" ]]; then
  LABEL="$2"
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
FILE="$SHARED_DIR/launch-$STAMP.json"

cat > "$FILE" <<EOF
{
  "action": "launch",
  "label": "$LABEL",
  "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo "Wrote launch command: $FILE"
