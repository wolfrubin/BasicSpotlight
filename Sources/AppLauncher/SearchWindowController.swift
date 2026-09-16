import Cocoa

final class SearchWindowController: NSWindowController {
    private let searchField = NSTextField()
    private let tableView = NSTableView()
    private let scrollView = NSScrollView()
    private let containerView = NSVisualEffectView()

    private var allApps: [AppEntry] = []
    private var filteredApps: [AppEntry] = []

    convenience init() {
        let width: CGFloat = 560
        let height: CGFloat = 400
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.init(window: panel)
        panel.delegate = self
        configureWindow(panel)
        configureViews(in: panel)
    }

    // MARK: - Setup

    private func configureWindow(_ panel: NSPanel) {
        panel.appearance = NSAppearance(named: .vibrantDark)
        panel.animationBehavior = .none
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
    }

    private func configureViews(in panel: NSPanel) {
        containerView.frame = panel.contentView!.bounds
        containerView.autoresizingMask = [.width, .height]
        containerView.material = .hudWindow
        containerView.blendingMode = .behindWindow
        containerView.state = .active
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = 12
        containerView.layer?.masksToBounds = true
        panel.contentView = containerView

        // View-backed layers default to a bottom-left anchor point (unlike plain
        // CALayers, which default to center), so re-anchor at the center for the
        // scale animation to grow outward evenly instead of from a corner.
        if let layer = containerView.layer {
            let frame = layer.frame
            layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            layer.position = CGPoint(x: frame.midX, y: frame.midY)
        }

        searchField.font = NSFont.systemFont(ofSize: 26, weight: .light)
        searchField.isBordered = false
        searchField.focusRingType = .none
        searchField.backgroundColor = .clear
        searchField.placeholderString = "Search Applications"
        searchField.delegate = self
        searchField.frame = NSRect(x: 20, y: panel.frame.height - 58, width: panel.frame.width - 40, height: 36)
        searchField.autoresizingMask = [.width, .minYMargin]
        containerView.addSubview(searchField)

        let divider = NSBox(frame: NSRect(x: 0, y: panel.frame.height - 62, width: panel.frame.width, height: 1))
        divider.boxType = .separator
        divider.autoresizingMask = [.width, .minYMargin]
        containerView.addSubview(divider)

        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.rowHeight = 44
        tableView.intercellSpacing = NSSize(width: 0, height: 0)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.doubleAction = #selector(rowDoubleClicked)
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("main"))
        column.width = panel.frame.width - 20
        tableView.addTableColumn(column)

        scrollView.frame = NSRect(x: 10, y: 10, width: panel.frame.width - 20, height: panel.frame.height - 72)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.documentView = tableView
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        containerView.addSubview(scrollView)
    }

    // MARK: - Show / hide

    func toggle() {
        if window?.isVisible == true {
            hide()
        } else {
            show()
        }
    }

    private func show() {
        guard let window else { return }
        allApps = AppFinder.loadApplications()
        filteredApps = allApps
        searchField.stringValue = ""
        tableView.reloadData()
        selectRow(0)
        centerOnScreen()

        window.alphaValue = 0
        animateScale(from: 0.96, to: 1.0)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(searchField)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
        }
    }

    private func hide() {
        guard let window, window.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.orderOut(nil)
            window.alphaValue = 1
        })
    }

    private func animateScale(from: CGFloat, to: CGFloat) {
        guard let layer = containerView.layer else { return }
        layer.transform = CATransform3DMakeScale(from, from, 1)
        let animation = CASpringAnimation(keyPath: "transform")
        animation.fromValue = CATransform3DMakeScale(from, from, 1)
        animation.toValue = CATransform3DMakeScale(to, to, 1)
        animation.damping = 18
        animation.initialVelocity = 4
        animation.duration = animation.settlingDuration
        layer.transform = CATransform3DMakeScale(to, to, 1)
        layer.add(animation, forKey: "scaleIn")
    }

    private func centerOnScreen() {
        guard let window, let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - window.frame.width / 2
        let y = screenFrame.midY - window.frame.height / 2 + screenFrame.height * 0.15
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - Filtering & selection

    private func filterApps(query: String) {
        if query.isEmpty {
            filteredApps = allApps
        } else {
            let lower = query.lowercased()
            filteredApps = allApps
                .filter { $0.name.lowercased().contains(lower) }
                .sorted { a, b in
                    let aStarts = a.name.lowercased().hasPrefix(lower)
                    let bStarts = b.name.lowercased().hasPrefix(lower)
                    if aStarts != bStarts { return aStarts }
                    return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                }
        }
        tableView.reloadData()
        selectRow(0)
    }

    private func selectRow(_ row: Int) {
        guard row >= 0, row < filteredApps.count else { return }
        tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        tableView.scrollRowToVisible(row)
    }

    private func moveSelection(by delta: Int) {
        guard !filteredApps.isEmpty else { return }
        let current = tableView.selectedRow
        let next = min(max(current + delta, 0), filteredApps.count - 1)
        selectRow(next)
    }

    private func openSelected() {
        let row = tableView.selectedRow
        guard row >= 0, row < filteredApps.count else { return }
        NSWorkspace.shared.open(filteredApps[row].url)
        hide()
    }

    @objc private func rowDoubleClicked() {
        openSelected()
    }
}

// MARK: - NSWindowDelegate

extension SearchWindowController: NSWindowDelegate {
    func windowDidResignKey(_ notification: Notification) {
        hide()
    }
}

// MARK: - NSTextFieldDelegate

extension SearchWindowController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        filterApps(query: searchField.stringValue)
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        switch commandSelector {
        case #selector(NSResponder.moveDown(_:)):
            moveSelection(by: 1)
            return true
        case #selector(NSResponder.moveUp(_:)):
            moveSelection(by: -1)
            return true
        case #selector(NSResponder.insertNewline(_:)):
            openSelected()
            return true
        case #selector(NSResponder.cancelOperation(_:)):
            hide()
            return true
        default:
            return false
        }
    }
}

// MARK: - NSTableViewDataSource / Delegate

extension SearchWindowController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        filteredApps.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("AppCell")
        let cell: AppCellView
        if let reused = tableView.makeView(withIdentifier: identifier, owner: self) as? AppCellView {
            cell = reused
        } else {
            cell = AppCellView()
            cell.identifier = identifier
        }
        let entry = filteredApps[row]
        cell.configure(name: entry.name, icon: entry.icon)
        return cell
    }
}
