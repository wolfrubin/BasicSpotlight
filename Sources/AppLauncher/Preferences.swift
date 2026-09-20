import Foundation

/// Backed by ~/Library/Preferences/com.wolfrubin.applauncher.plist, editable via
/// `defaults write com.wolfrubin.applauncher SearchPaths -array ...`.
enum Preferences {
    static let suiteName = "com.wolfrubin.applauncher"
    static let searchPathsKey = "SearchPaths"
    static let defaultSearchPaths = ["/Applications", "/System/Applications"]
    static let excludedPathsKey = "ExcludedPaths"
    static let defaultExcludedPaths: [String] = []
    static let minimumAudioDurationKey = "MinimumAudioDurationSeconds"
    static let defaultMinimumAudioDuration: Double = 60

    private static let defaults: UserDefaults = {
        let store = UserDefaults(suiteName: suiteName) ?? .standard
        store.register(defaults: [
            searchPathsKey: defaultSearchPaths,
            excludedPathsKey: defaultExcludedPaths,
            minimumAudioDurationKey: defaultMinimumAudioDuration
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

    /// Audio results shorter than this are treated as samples/loops/one-shots
    /// rather than full tracks, and excluded from Audio Files search.
    static var minimumAudioDurationSeconds: Double {
        defaults.double(forKey: minimumAudioDurationKey)
    }
}
