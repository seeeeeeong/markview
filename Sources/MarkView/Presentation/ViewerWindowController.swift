import AppKit

final class ViewerWindowController: NSWindowController {
    let fileURL: URL

    private let rendererView: RendererView
    private var fileWatcher: FileWatcher?
    private var appearanceObservation: NSKeyValueObservation?

    init(fileURL: URL) {
        self.fileURL = fileURL
        rendererView = RendererViewPool.shared.take()

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = fileURL.lastPathComponent
        window.representedURL = fileURL
        window.setFrameAutosaveName("viewer-window")
        window.tabbingMode = .preferred
        super.init(window: window)

        rendererView.delegate = self
        rendererView.autoresizingMask = [.width, .height]
        rendererView.frame = window.contentView!.bounds
        window.contentView!.addSubview(rendererView)

        render()
        startWatching()
        observeSystemAppearance()
        NSDocumentController.shared.noteNewRecentDocumentURL(fileURL)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func render() {
        let source: String
        do {
            source = try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            presentAlert("Cannot read \(fileURL.path): \(error.localizedDescription)")
            return
        }
        rendererView.render(RenderRequest.current(source: source, fileURL: fileURL))
    }

    private func startWatching() {
        let watcher = FileWatcher(url: fileURL) { [weak self] in
            self?.render()
        }
        watcher.start()
        fileWatcher = watcher
    }

    private func observeSystemAppearance() {
        appearanceObservation = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in
            DispatchQueue.main.async {
                if AppearanceStore.theme == .system { self?.render() }
            }
        }
    }

    private func presentAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "MarkView"
        alert.informativeText = message
        alert.runModal()
    }

    @objc func reloadDocument(_ sender: Any?) {
        render()
    }

    @objc func increaseFontSize(_ sender: Any?) {
        AppearanceStore.fontSize += 1
        render()
    }

    @objc func decreaseFontSize(_ sender: Any?) {
        AppearanceStore.fontSize -= 1
        render()
    }

    @objc func resetFontSize(_ sender: Any?) {
        AppearanceStore.fontSize = AppearanceStore.defaultFontSize
        render()
    }
}

extension ViewerWindowController: RendererViewDelegate {
    func rendererView(_ view: RendererView, didRequestOpen url: URL) {
        let viewableExtensions = ["md", "markdown", "mdown", "mmd", "mermaid"]
        if url.isFileURL, viewableExtensions.contains(url.pathExtension.lowercased()) {
            (NSApp.delegate as? AppDelegate)?.openDocument(at: url)
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    func rendererView(_ view: RendererView, didReportError message: String) {
        NSLog("MarkView renderer error: %@", message)
    }

    func rendererViewDidFailToLoadAssets(_ view: RendererView) {
        presentAlert("Renderer assets not found. Rebuild the app with make-app.sh.")
    }
}
