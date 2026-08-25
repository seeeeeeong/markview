import AppKit

final class RendererViewPool {
    static let shared = RendererViewPool()

    private var spare: RendererView?

    func warmUp() {
        guard spare == nil else { return }
        spare = RendererView(frame: NSRect(x: 0, y: 0, width: 900, height: 760))
        DebugLog.write("spare renderer warmed")
    }

    func take() -> RendererView {
        let view = spare ?? RendererView(frame: NSRect(x: 0, y: 0, width: 900, height: 760))
        spare = nil
        DispatchQueue.main.async { [weak self] in
            self?.warmUp()
        }
        return view
    }
}
