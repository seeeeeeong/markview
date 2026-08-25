import AppKit
import WebKit

/// One window = one markdown document, rendered by the bundled md-lens renderer.
/// This controller plays the role of md-lens's JCEF host: it connects to the
/// `window.mdLens` bridge, feeds RenderRequests, and injects runtimes on demand.
func debugLog(_ message: String) {
    guard let path = ProcessInfo.processInfo.environment["MDLENS_DEBUG_LOG"] else { return }
    let line = "\(Date()) \(message)\n"
    if let handle = FileHandle(forWritingAtPath: path) {
        handle.seekToEndOfFile()
        handle.write(line.data(using: .utf8)!)
        try? handle.close()
    } else {
        try? line.write(toFile: path, atomically: true, encoding: .utf8)
    }
}

final class ViewerWindowController: NSWindowController {
    private let fileURL: URL
    private var webView: WKWebView!
    private var bridgeReady = false
    private var fileWatcher: DispatchSourceFileSystemObject?
    private var appearanceObservation: NSKeyValueObservation?

    var fontSize: Int {
        get { max(12, min(24, UserDefaults.standard.object(forKey: "fontSize") as? Int ?? 15)) }
        set { UserDefaults.standard.set(max(12, min(24, newValue)), forKey: "fontSize") }
    }

    init(fileURL: URL) {
        self.fileURL = fileURL
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = fileURL.lastPathComponent
        window.representedURL = fileURL
        window.setFrameAutosaveName("MdLensViewer")
        window.tabbingMode = .preferred
        super.init(window: window)

        let controller = WKUserContentController()
        controller.add(BridgeMessageProxy(target: self), name: "host")
        let config = WKWebViewConfiguration()
        config.userContentController = controller

        webView = WKWebView(frame: window.contentView!.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.allowsMagnification = true
        window.contentView!.addSubview(webView)

        loadRendererPage()
        startWatchingFile()
        observeAppearance()
        NSDocumentController.shared.noteNewRecentDocumentURL(fileURL)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    deinit {
        fileWatcher?.cancel()
    }

    // MARK: - Renderer page

    private func loadRendererPage() {
        guard let indexURL = RendererResources.indexURL else {
            presentError("Renderer resources not found. Rebuild the app with make-app.sh.")
            return
        }
        // Read access to "/" lets the page load images referenced by the
        // markdown file from anywhere on disk (local trusted viewer).
        webView.loadFileURL(indexURL, allowingReadAccessTo: URL(fileURLWithPath: "/"))
    }

    private func connectBridge() {
        // Polls until the page's module script has installed window.mdLens —
        // on cold starts didFinish can arrive before the module executes.
        let shim = """
        (function connect() {
          if (!window.mdLens) { setTimeout(connect, 50); return; }
          const post = (m) => window.webkit.messageHandlers.host.postMessage(m);
          window.mdLens.connect({
            error: (message) => post({ type: "error", message: String(message) }),
            loadRuntime: (name) => post({ type: "loadRuntime", name: String(name) }),
            openLink: (href) => post({ type: "openLink", href: String(href) }),
            ready: () => post({ type: "ready" }),
            rendered: () => post({ type: "rendered" }),
          });
        })();
        """
        webView.evaluateJavaScript(shim) { _, error in
            if let error {
                NSLog("MdLens connect failed: %@", String(describing: error))
                debugLog("connect failed: \(error)")
            } else {
                debugLog("connect evaluated ok")
            }
        }
    }

    // MARK: - Rendering

    func render() {
        guard bridgeReady else { return }
        let source: String
        do {
            source = try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            presentError("Cannot read \(fileURL.path): \(error.localizedDescription)")
            return
        }

        let isMermaid = ["mmd", "mermaid"].contains(fileURL.pathExtension.lowercased())
        let request: [String: Any] = [
            "version": 5,
            "source": source,
            "baseUrl": fileURL.deletingLastPathComponent().absoluteString,
            "documentType": isMermaid ? "mermaid" : "markdown",
            "theme": Settings.theme.resolved,
            "profile": Settings.profile,
            "fontFamily": "",
            "fontSize": fontSize,
            "maxContentWidth": 1152,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: request),
              let json = String(data: data, encoding: .utf8) else { return }

        // Point <base> at the document's directory so relative image paths resolve.
        let baseHref = fileURL.deletingLastPathComponent().absoluteString
        let script = """
        (function () {
          let base = document.querySelector("base");
          if (!base) { base = document.createElement("base"); document.head.prepend(base); }
          base.href = \(jsString(baseHref));
          window.mdLens.render(\(json));
        })();
        """
        webView.evaluateJavaScript(script) { _, error in
            if let error {
                NSLog("MdLens render failed: %@", String(describing: error))
                debugLog("render failed: \(error)")
            } else {
                debugLog("render evaluated ok")
            }
        }
    }

    private func jsString(_ value: String) -> String {
        let data = try? JSONSerialization.data(withJSONObject: [value])
        let encoded = data.flatMap { String(data: $0, encoding: .utf8) } ?? "[\"\"]"
        return String(encoded.dropFirst().dropLast())
    }

    // MARK: - Bridge messages from the renderer

    fileprivate func handleBridgeMessage(_ body: [String: Any]) {
        debugLog("bridge message: \(body)")
        switch body["type"] as? String {
        case "ready":
            bridgeReady = true
            render()
        case "loadRuntime":
            injectRuntime(named: body["name"] as? String ?? "")
        case "openLink":
            openLink(body["href"] as? String ?? "")
        case "error":
            NSLog("MdLens renderer error: %@", body["message"] as? String ?? "unknown")
        case "rendered", .none, .some:
            break
        }
    }

    private func injectRuntime(named name: String) {
        guard let script = RendererResources.runtimeScript(named: name) else {
            webView.evaluateJavaScript(
                "window.mdLens.runtimeFailed(\(jsString(name)), \(jsString("runtime not bundled")));"
            )
            return
        }
        // "; 0" keeps the completion value serializable — some runtime bundles
        // end in an expression WKWebView cannot marshal, which would otherwise
        // surface as a bogus injection error.
        webView.evaluateJavaScript(script + "\n;0") { [weak self] _, error in
            guard let self else { return }
            if let error {
                self.webView.evaluateJavaScript(
                    "window.mdLens.runtimeFailed(\(self.jsString(name)), \(self.jsString(error.localizedDescription)));"
                )
            } else {
                self.webView.evaluateJavaScript("window.mdLens.runtimeReady(\(self.jsString(name)));")
            }
        }
    }

    private func openLink(_ href: String) {
        guard let url = URL(string: href) else { return }
        if url.isFileURL, ["md", "markdown", "mmd", "mermaid"].contains(url.pathExtension.lowercased()) {
            (NSApp.delegate as? AppDelegate)?.openDocument(at: url)
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - File watching (auto reload)

    private func startWatchingFile() {
        let fd = open(fileURL.path, O_EVTONLY)
        guard fd >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .delete, .rename],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            guard let self else { return }
            let events = source.data
            if events.contains(.delete) || events.contains(.rename) {
                // Atomic save: the inode is gone; re-arm on the new file.
                source.cancel()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.startWatchingFile()
                    self.render()
                }
            } else {
                self.render()
            }
        }
        source.setCancelHandler { _ = Darwin.close(fd) }
        source.resume()
        fileWatcher?.cancel()
        fileWatcher = source
    }

    // MARK: - Appearance / settings changes

    private func observeAppearance() {
        appearanceObservation = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in
            DispatchQueue.main.async {
                if Settings.theme == .system { self?.render() }
            }
        }
    }

    private func presentError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "MdLens"
        alert.informativeText = message
        alert.runModal()
    }

    // MARK: - Menu actions

    @objc func reloadDocument(_ sender: Any?) { render() }

    @objc func increaseFontSize(_ sender: Any?) {
        fontSize += 1
        render()
    }

    @objc func decreaseFontSize(_ sender: Any?) {
        fontSize -= 1
        render()
    }

    @objc func resetFontSize(_ sender: Any?) {
        fontSize = 15
        render()
    }
}

extension ViewerWindowController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        debugLog("didFinish navigation")
        connectBridge()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        debugLog("didFail: \(error)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        debugLog("didFailProvisional: \(error)")
    }
}

/// Breaks the retain cycle WKUserContentController → handler → controller.
private final class BridgeMessageProxy: NSObject, WKScriptMessageHandler {
    weak var target: ViewerWindowController?

    init(target: ViewerWindowController) {
        self.target = target
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let body = message.body as? [String: Any] else { return }
        target?.handleBridgeMessage(body)
    }
}
