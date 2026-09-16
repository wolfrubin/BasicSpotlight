#!/usr/bin/env bash
# Stops and removes everything install.sh set up. Leaves preferences
# (~/Library/Preferences/com.wolfrubin.applauncher.plist) in place.
set -euo pipefail

LABEL="com.wolfrubin.applauncher"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"
INSTALL_DIR="$HOME/Library/Application Support/AppLauncher"

echo "Stopping LaunchAgent..."
launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true

echo "Removing installed files..."
rm -f "$PLIST_PATH"
rm -rf "$INSTALL_DIR"

echo
echo "Uninstalled. Preferences were left in place; remove them with:"
echo "  defaults delete $LABEL"
