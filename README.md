# BasicSpotlight

A minimal, native Spotlight-style app launcher for macOS. Press **Cmd+Space**, type an app name, hit Enter — it searches `/Applications` and `/System/Applications` (including apps nested one folder deep, e.g. `rekordbox`) and launches whatever you pick. That's all it does.

## Requirements

- macOS 12 or later
- Swift toolchain (Xcode Command Line Tools are enough — no full Xcode needed):
  ```
  xcode-select --install
  ```

## Install

```bash
git clone https://github.com/wolfrubin/BasicSpotlight.git
cd BasicSpotlight
./install.sh
```

This builds the release binary, copies it to `~/Library/Application Support/AppLauncher/`, and installs a LaunchAgent (`~/Library/LaunchAgents/com.wolfrubin.applauncher.plist`) so it starts at login and restarts if it ever crashes. Re-running `./install.sh` after pulling new changes rebuilds and reloads it.

To remove everything the installer set up:
```bash
./uninstall.sh
```

<details>
<summary>Installing by hand instead</summary>

1. Build:
   ```bash
   swift build -c release
   ```

2. Copy the binary somewhere permanent:
   ```bash
   mkdir -p "$HOME/Library/Application Support/AppLauncher"
   cp .build/release/AppLauncher "$HOME/Library/Application Support/AppLauncher/AppLauncher"
   ```

3. Create a LaunchAgent so it starts automatically at login and restarts if it ever crashes. Save this as `~/Library/LaunchAgents/com.yourname.applauncher.plist` (replace `yourname` and the `$HOME`-expanded path with your actual home directory, since plists don't expand `$HOME`):
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>Label</key>
       <string>com.yourname.applauncher</string>
       <key>ProgramArguments</key>
       <array>
           <string>/Users/yourname/Library/Application Support/AppLauncher/AppLauncher</string>
       </array>
       <key>RunAtLoad</key>
       <true/>
       <key>KeepAlive</key>
       <true/>
       <key>ProcessType</key>
       <string>Interactive</string>
       <key>StandardOutPath</key>
       <string>/tmp/applauncher.log</string>
       <key>StandardErrorPath</key>
       <string>/tmp/applauncher.log</string>
   </dict>
   </plist>
   ```

4. Load it:
   ```bash
   launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.yourname.applauncher.plist
   ```

Note: if you rename the Label here, also update `Preferences.suiteName` in `Sources/AppLauncher/Preferences.swift` to match, or the [configurable search paths](#configuring-search-paths) setting will read from the wrong `defaults` domain.

</details>

## macOS setup

Two one-time steps are needed before Cmd+Space will actually reach this app instead of the system.

### 1. Free up the Cmd+Space shortcut

macOS binds Cmd+Space to Spotlight by default, and the system claims it before any third-party app ever sees the key press — so until this is done, Cmd+Space will keep opening Apple's Spotlight instead.

1. Open **System Settings**.
2. Go to **Keyboard → Keyboard Shortcuts…**.
3. Select **Spotlight** in the sidebar.
4. Uncheck **"Show Spotlight search"** (or click its shortcut and press a different key combo if you'd rather keep Spotlight reachable another way).
5. While there, also check **Input Sources** in the sidebar — "Select the previous input source" defaults to Ctrl+Space on some Macs and can cause similar conflicts if you ever rebind this app's hotkey to Ctrl+Space instead.
6. Close System Settings.

### 2. Grant App Management permission

The first time you press Cmd+Space after installing, macOS will show a prompt like *"AppLauncher would like to access files in your Applications folder"* or *"...would like to manage other applications"* — this is expected. Reading every app's bundle to build the search list requires this permission (added in macOS Ventura), since it's the same access pattern malware uses to tamper with other apps.

- Click **Allow** when prompted.
- If you missed it or need to re-enable it later, go to **System Settings → Privacy & Security → App Management** and toggle AppLauncher on.

Once both are done, Cmd+Space opens this app.

## Configuring search paths

By default the app searches `/Applications` and `/System/Applications`. This is stored in the standard macOS place for app settings — `UserDefaults`, backed by `~/Library/Preferences/com.wolfrubin.applauncher.plist` — and can be read or changed with the `defaults` command.

Add or replace the list of folders it searches:
```bash
defaults write com.wolfrubin.applauncher SearchPaths -array "/Applications" "/System/Applications" "/Applications/Utilities"
```

Check the current setting:
```bash
defaults read com.wolfrubin.applauncher SearchPaths
```

Reset to the built-in defaults:
```bash
defaults delete com.wolfrubin.applauncher SearchPaths
```

Changes take effect the next time you open the search panel — no need to restart the app. Each folder is searched one level deep, so apps nested in a named subfolder (like `rekordbox`) are still found.

## Usage

| Key | Action |
|---|---|
| `Cmd+Space` | Toggle the search panel |
| Type | Filter apps live |
| `↑` / `↓` | Move selection |
| `Enter` | Launch selected app |
| `Esc` / click away | Dismiss |

## Uninstall

```bash
launchctl bootout gui/$(id -u)/com.yourname.applauncher
rm ~/Library/LaunchAgents/com.yourname.applauncher.plist
rm -rf "$HOME/Library/Application Support/AppLauncher"
```
