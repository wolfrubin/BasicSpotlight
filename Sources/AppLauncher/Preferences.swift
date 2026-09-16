import Foundation

/// Backed by ~/Library/Preferences/com.wolfrubin.applauncher.plist, editable via
/// `defaults write com.wolfrubin.applauncher SearchPaths -array ...`.
enum Preferences {
    static let suiteName = "com.wolfrubin.applauncher"
    static let searchPathsKey = "SearchPaths"
    static let defaultSearchPaths = ["/Applications", "/System/Applications"]

    private static let defaults: UserDefaults = {
        let store = UserDefaults(suiteName: suiteName) ?? .standard
        store.register(defaults: [searchPathsKey: defaultSearchPaths])
        return store
    }()

    static var searchPaths: [String] {
        (defaults.array(forKey: searchPathsKey) as? [String]) ?? defaultSearchPaths
    }
}
