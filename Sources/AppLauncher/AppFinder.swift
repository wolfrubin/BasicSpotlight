import Cocoa

struct AppEntry {
    let name: String
    let url: URL
    let icon: NSImage
}

enum AppFinder {
    /// /Applications holds user-installed apps; built-in Apple apps (System Settings,
    /// Safari, Calculator, etc.) live in /System/Applications.
    private static let searchDirectories = ["/Applications", "/System/Applications"]

    static func loadApplications() -> [AppEntry] {
        let fileManager = FileManager.default
        var seenNames = Set<String>()
        var entries: [AppEntry] = []

        func addApp(at url: URL) {
            let name = url.deletingPathExtension().lastPathComponent
            guard seenNames.insert(name).inserted else { return }
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            entries.append(AppEntry(name: name, url: url, icon: icon))
        }

        for directory in searchDirectories {
            let directoryURL = URL(fileURLWithPath: directory)
            guard let contents = try? fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [.isDirectoryKey]) else {
                continue
            }
            for url in contents {
                if url.pathExtension == "app" {
                    addApp(at: url)
                } else if (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                    // Some installers (e.g. rekordbox) nest the .app one level inside a
                    // named subfolder instead of placing it directly in /Applications.
                    let nested = (try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []
                    for nestedURL in nested where nestedURL.pathExtension == "app" {
                        addApp(at: nestedURL)
                    }
                }
            }
        }

        return entries.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
