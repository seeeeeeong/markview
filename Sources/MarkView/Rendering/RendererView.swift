import AppKit
import WebKit

protocol RendererViewDelegate: AnyObject {
    func rendererView(_ view: RendererView, didRequestOpen url: URL)
    func rendererView(_ view: RendererView, didReportError message: String)
    func rendererViewDidFailToLoadAssets(_ view: RendererView)
}

final class RendererView: NSView {
    weak var delegate: RendererViewDelegate?

    private let webView: WKWebView
    private var isBridgeConnected = false
    private var pendingRequest: RenderRequest?

    override init(frame frameRect: NSRect) {
        let contentController = WKUserContentController()
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        configuration.setURLSchemeHandler(RendererSchemeHandler(), forURLScheme: RendererSchemeHandler.scheme)
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init(frame: frameRect)

        contentController.add(WeakMessageHandler(target: self), name: Bridge.handlerName)
        webView.navigationDelegate = self
        webView.allowsMagnification = true
        webView.autoresizingMask = [.width, .height]
        webView.frame = bounds
        addSubview(webView)
        loadRendererPage()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func render(_ request: RenderRequest) {
        guard isBridgeConnected else {
            pendingRequest = request
            return
        }
        dispatch(request)
    }

    private func loadRendererPage() {
        guard RendererAssets.indexURL != nil else {
            delegate?.rendererViewDidFailToLoadAssets(self)
            return
        }
        webView.load(URLRequest(url: RendererSchemeHandler.indexURL))
    }

    private func dispatch(_ request: RenderRequest) {
        guard let json = request.encodedJSON() else { return }
        let skinCSS = RendererAssets.skinCSS(for: AppearanceStore.skin) ?? ""
        let script = """
        (function () {
          let base = document.querySelector("base");
          if (!base) { base = document.createElement("base"); document.head.prepend(base); }
          base.href = \(Bridge.quote(documentBase(from: request.baseUrl)));
          let skin = document.getElementById("markview-skin");
          if (!skin) {
            skin = document.createElement("style");
            skin.id = "markview-skin";
            document.head.append(skin);
          }
          skin.textContent = \(Bridge.quote(skinCSS));
          window.mdLens.render(\(json));
        })();
        """
        webView.evaluateJavaScript(script) { _, error in
            if let error { DebugLog.write("render dispatch failed: \(error)") }
        }
    }

    private func documentBase(from baseUrl: String) -> String {
        guard let url = URL(string: baseUrl), url.isFileURL else { return baseUrl }
        return RendererSchemeHandler.documentBase(for: url)
    }

    private func connectBridge() {
        webView.evaluateJavaScript(Bridge.connectScript) { _, error in
            if let error { DebugLog.write("bridge connect failed: \(error)") }
        }
    }

    fileprivate func handleMessage(_ body: [String: Any]) {
        DebugLog.write("bridge message: \(body)")
        switch body["type"] as? String {
        case "ready":
            isBridgeConnected = true
            if let request = pendingRequest {
                pendingRequest = nil
                dispatch(request)
            }
        case "loadRuntime":
            injectRuntime(named: body["name"] as? String ?? "")
        case "openLink":
            if let url = URL(string: body["href"] as? String ?? "") {
                delegate?.rendererView(self, didRequestOpen: url)
            }
        case "error":
            delegate?.rendererView(self, didReportError: body["message"] as? String ?? "unknown")
        default:
            break
        }
    }

    private func injectRuntime(named name: String) {
        guard let script = RendererAssets.runtimeScript(named: name) else {
            notifyRuntime(name: name, failure: "runtime not bundled")
            return
        }
        webView.evaluateJavaScript(script + "\n;0") { [weak self] _, error in
            if let error {
                self?.notifyRuntime(name: name, failure: error.localizedDescription)
            } else {
                self?.notifyRuntime(name: name, failure: nil)
            }
        }
    }

    private func notifyRuntime(name: String, failure: String?) {
        let call = failure.map {
            "window.mdLens.runtimeFailed(\(Bridge.quote(name)), \(Bridge.quote($0)));"
        } ?? "window.mdLens.runtimeReady(\(Bridge.quote(name)));"
        webView.evaluateJavaScript(call)
    }
}

extension RendererView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        connectBridge()
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        DebugLog.write("navigation failed: \(error)")
    }
}

private enum Bridge {
    static let handlerName = "host"

    static let connectScript = """
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

    static func quote(_ value: String) -> String {
        let data = try? JSONSerialization.data(withJSONObject: [value])
        let encoded = data.flatMap { String(data: $0, encoding: .utf8) } ?? "[\"\"]"
        return String(encoded.dropFirst().dropLast())
    }
}

private final class WeakMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var target: RendererView?

    init(target: RendererView) {
        self.target = target
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let body = message.body as? [String: Any] else { return }
        target?.handleMessage(body)
    }
}
