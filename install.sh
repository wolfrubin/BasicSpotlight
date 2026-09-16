#!/usr/bin/env bash
# Builds and installs BasicSpotlight as a LaunchAgent that starts at login.
# Label must match Preferences.suiteName in Sources/AppLauncher/Preferences.swift.
set -euo pipefail

LABEL="com.wolfrubin.applauncher"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/Library/Application Support/AppLauncher"
BINARY_PATH="$INSTALL_DIR/AppLauncher"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG_PATH="/tmp/applauncher.log"

echo "Building BasicSpotlight..."
cd "$REPO_DIR"
swift build -c release

echo "Installing binary to $BINARY_PATH"
mkdir -p "$INSTALL_DIR"
cp "$REPO_DIR/.build/release/AppLauncher" "$BINARY_PATH"

echo "Writing LaunchAgent to $PLIST_PATH"
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BINARY_PATH</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ProcessType</key>
    <string>Interactive</string>
    <key>StandardOutPath</key>
    <string>$LOG_PATH</string>
    <key>StandardErrorPath</key>
    <string>$LOG_PATH</string>
</dict>
</plist>
PLIST

echo "Loading LaunchAgent..."
launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true

# bootstrap can transiently fail with an I/O error if it races the bootout
# above (launchd hasn't finished tearing down the old service yet).
for attempt in 1 2 3 4 5; do
    if launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null; then
        break
    fi
    if [ "$attempt" -eq 5 ]; then
        echo "Failed to load the LaunchAgent after several attempts." >&2
        exit 1
    fi
    sleep 0.5
done

echo
echo "Installed and running. Press Cmd+Space to open BasicSpotlight."
echo "If Cmd+Space opens Apple's Spotlight instead, or you're prompted for App"
echo "Management access, see the 'macOS setup' section in README.md."
