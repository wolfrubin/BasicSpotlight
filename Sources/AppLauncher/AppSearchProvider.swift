import Cocoa

final class AppSearchProvider: SearchProvider {
    func search(query: String, onUpdate: @escaping ([SearchResult]) -> Void) {
        let apps = AppFinder.loadApplications()
        onUpdate(Self.filter(apps, query: query))
    }

    func cancel() {}

    private static func filter(_ apps: [SearchResult], query: String) -> [SearchResult] {
        guard !query.isEmpty else { return apps }
        let lower = query.lowercased()
        return apps
            .filter { $0.name.lowercased().contains(lower) }
            .sorted { a, b in
                let aStarts = a.name.lowercased().hasPrefix(lower)
                let bStarts = b.name.lowercased().hasPrefix(lower)
                if aStarts != bStarts { return aStarts }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
    }
}
