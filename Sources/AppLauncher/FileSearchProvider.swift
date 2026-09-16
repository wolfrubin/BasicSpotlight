import Cocoa

/// Searches files by name, scoped to a given content type (a Uniform Type
/// Identifier, e.g. "public.audio"), using NSMetadataQuery as the backend.
///
/// This queries Spotlight's existing file index rather than crawling the
/// filesystem ourselves — no custom index to build or keep up to date. All of
/// this is hidden behind SearchProvider, so the backend can be replaced later
/// (e.g. with a custom index) without touching the UI.
final class FileSearchProvider: NSObject, SearchProvider {
    private let contentType: String
    private let maxResults = 50
    private var query: NSMetadataQuery?

    init(contentType: String) {
        self.contentType = contentType
    }

    func search(query text: String, onUpdate: @escaping ([SearchResult]) -> Void) {
        cancel()

        // An unscoped query against "contains" would try to match every file on
        // disk; require a couple of characters before asking Spotlight to search.
        guard text.count >= 2 else {
            onUpdate([])
            return
        }

        var predicates: [NSPredicate] = [
            NSPredicate(format: "kMDItemFSName CONTAINS[cd] %@", text),
            NSPredicate(format: "kMDItemContentTypeTree == %@", contentType),
            // Files inside an app bundle are that app's internal resources
            // (e.g. Ableton's Core Library samples), never something to open directly.
            NSPredicate(format: "NOT (kMDItemPath CONTAINS[cd] %@)", ".app/")
        ]
        for excluded in Preferences.excludedPaths {
            predicates.append(NSPredicate(format: "NOT (kMDItemPath BEGINSWITH[cd] %@)", excluded))
        }

        let metadataQuery = NSMetadataQuery()
        metadataQuery.searchScopes = [NSMetadataQueryLocalComputerScope]
        metadataQuery.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        metadataQuery.sortDescriptors = [NSSortDescriptor(key: NSMetadataItemFSNameKey, ascending: true)]
        metadataQuery.operationQueue = .main

        NotificationCenter.default.addObserver(
            self, selector: #selector(handleUpdate(_:)),
            name: .NSMetadataQueryDidFinishGathering, object: metadataQuery
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleUpdate(_:)),
            name: .NSMetadataQueryDidUpdate, object: metadataQuery
        )

        self.query = metadataQuery
        self.onUpdate = onUpdate
        metadataQuery.start()
    }

    func cancel() {
        guard let query else { return }
        query.stop()
        NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidFinishGathering, object: query)
        NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidUpdate, object: query)
        self.query = nil
        self.onUpdate = nil
    }

    private var onUpdate: (([SearchResult]) -> Void)?

    @objc private func handleUpdate(_ notification: Notification) {
        // Guard against a notification from a query we've since replaced.
        guard let metadataQuery = notification.object as? NSMetadataQuery, metadataQuery === query else { return }

        metadataQuery.disableUpdates()
        let items = metadataQuery.results as? [NSMetadataItem] ?? []
        let results: [SearchResult] = items.prefix(maxResults).compactMap { item in
            guard let path = item.value(forAttribute: NSMetadataItemPathKey) as? String else { return nil }
            let name = (item.value(forAttribute: NSMetadataItemFSNameKey) as? String)
                ?? (path as NSString).lastPathComponent
            let url = URL(fileURLWithPath: path)
            let icon = NSWorkspace.shared.icon(forFile: path)
            return SearchResult(name: name, url: url, icon: icon)
        }
        metadataQuery.enableUpdates()

        onUpdate?(results)
    }
}
