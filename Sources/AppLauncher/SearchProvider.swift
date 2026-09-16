import Cocoa

struct SearchResult {
    let name: String
    let url: URL
    let icon: NSImage
}

/// A pluggable source of search results. The UI only depends on this protocol,
/// so the backend for a given mode (e.g. NSMetadataQuery for files) can be
/// swapped out later without any changes to SearchWindowController.
protocol SearchProvider: AnyObject {
    /// Runs (or re-runs) a search for `query`, invoking `onUpdate` on the main
    /// thread with the current best set of results. May call `onUpdate` more
    /// than once as results stream in (e.g. from a live NSMetadataQuery).
    func search(query: String, onUpdate: @escaping ([SearchResult]) -> Void)

    /// Cancels any in-flight search. Called before starting a new one.
    func cancel()
}
