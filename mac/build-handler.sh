#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$ROOT_DIR/Sail3dlForwarder.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
FORWARD_TARGET="${SAIL3DL_FORWARD_TARGET:-http://127.0.0.1:4567/launch}"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Sail3dlForwarder</string>
    <key>CFBundleIdentifier</key>
    <string>local.vmbridge.sail3dlforwarder</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Sail3dlForwarder</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleURLTypes</key>
    <array>
      <dict>
        <key>CFBundleURLName</key>
        <string>local.vmbridge.sail3dl</string>
        <key>CFBundleURLSchemes</key>
        <array>
          <string>sail3dl</string>
        </array>
      </dict>
    </array>
  </dict>
</plist>
EOF

cat > "$MACOS_DIR/Sail3dlForwarder" <<EOF
#!/usr/bin/env bash
set -euo pipefail
URL="\${1:-}"
if [[ -z "\$URL" ]]; then
  exit 0
fi
/usr/bin/curl -fsS -X POST \
  -H 'Content-Type: application/json' \
  --data-binary @- \
  '${FORWARD_TARGET}' <<JSON
{"url":"\$URL"}
JSON
EOF

chmod +x "$MACOS_DIR/Sail3dlForwarder"

echo "Built app: $APP_DIR"
echo "Forward target: $FORWARD_TARGET"
echo "Open it once to register the sail3dl:// scheme:"
echo "  open \"$APP_DIR\""
