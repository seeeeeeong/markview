# MarkView

A native macOS markdown viewer with GitHub-style rendering.
Syntax highlighting (Shiki / VS Code grammars), Mermaid diagrams, KaTeX math,
GitHub alerts, footnotes, and task lists — in a lightweight AppKit app.

## Install

Download the latest `MarkView-x.y.z.dmg` from
[Releases](https://github.com/sinseonglee/markview/releases), open it, and drag
MarkView to Applications.

The app is not notarized yet, so on first launch macOS may block it. Either
right-click the app and choose **Open**, or run:

```bash
xattr -d com.apple.quarantine /Applications/MarkView.app
```

## Build from source

```bash
./make-app.sh    # → MarkView.app
./make-dmg.sh    # → MarkView-x.y.z.dmg
```

Requires Xcode command line tools (Swift 5.9+).

## Usage

- Open with `open -a MarkView some.md`, Finder "Open With", or Cmd-O
- Multiple windows; supports `.md` `.markdown` `.mdown` `.mmd` `.mermaid`
  (`.mmd` renders as a standalone Mermaid document)
- Auto-reloads when the file changes (including editors' atomic saves)

## View menu

| Item | Values |
|---|---|
| Theme | System / Light / Dark |
| Style | GitHub / LaTeX / Tufte |
| Profile | Compact / Spacious |
| Font | System default + installed recommended families |
| Content Width | 768–1536 px / Full Width |
| Accent Colors | Headings, Bold, Inline Code — Off + 8 presets |
| Text size | Cmd +/-/0 (12–24 px) |

## Architecture

```
Sources/MarkView/
  App/           # bootstrap, AppDelegate, menu construction
  Domain/        # appearance settings, render request model
  Rendering/     # WKWebView renderer host, bundled asset lookup
  Presentation/  # document viewer window
  Support/       # file watching, debug logging
resources/
  renderer/      # prebuilt rendering engine
  skins/         # LaTeX and Tufte style CSS
```

Third-party notices ship in the app's About panel (Credits).

Debugging: set `MARKVIEW_DEBUG_LOG=/tmp/markview.log` to log bridge events.

## License

MIT — see [LICENSE](LICENSE). Bundled third-party components remain under
their original licenses, listed in [Credits.rtf](Credits.rtf).
