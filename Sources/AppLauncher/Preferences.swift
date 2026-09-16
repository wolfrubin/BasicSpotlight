import Foundation

/// Backed by ~/Library/Preferences/com.wolfrubin.applauncher.plist, editable via
/// `defaults write com.wolfrubin.applauncher SearchPaths -array ...`.
enum Preferences {
    static let suiteName = "com.wolfrubin.applauncher"
    static let searchPathsKey = "SearchPaths"
    static let defaultSearchPaths = ["/Applications", "/System/Applications"]
    static let excludedPathsKey = "ExcludedPaths"
    static let defaultExcludedPaths: [String] = []

    private static let defaults: UserDefaults = {
        let store = UserDefaults(suiteName: suiteName) ?? .standard
        store.register(defaults: [
            searchPathsKey: defaultSearchPaths,
            excludedPathsKey: defaultExcludedPaths
        ])
        return store
    }()

    static var searchPaths: [String] {
        (defaults.array(forKey: searchPathsKey) as? [String]) ?? defaultSearchPaths
    }

    /// Additional path prefixes to exclude from file search, on top of the
    /// always-applied rule that skips anything inside a .app bundle.
    static var excludedPaths: [String] {
        (defaults.array(forKey: excludedPathsKey) as? [String]) ?? defaultExcludedPaths
    }
}
