# MdLens for Mac

[md-lens](https://github.com/Hyune-s-lab/md-lens) (IntelliJ용 마크다운 뷰어)의 렌더러를
그대로 번들한 네이티브 macOS 마크다운 뷰어. 렌더링 스타일이 md-lens와 동일하다
(GitHub Light/Dark + marked + highlight.js + KaTeX + Mermaid).

## 빌드

```bash
./make-app.sh    # → MdLens.app
```

## 사용

- `open -a "$PWD/MdLens.app" some.md` 또는 Finder에서 "다음으로 열기"
- Cmd-O 로 파일 열기, 여러 창 지원
- 파일 변경 시 자동 리로드 (에디터의 atomic save 포함)
- View 메뉴: Theme (System/Light/Dark), Profile (Compact/Spacious), 글자 크기 (Cmd +/-/0)
- `.md` `.markdown` `.mmd` `.mermaid` 지원 — `.mmd`는 단독 Mermaid 문서로 렌더링

## 구조

```
Sources/MdLens/
  main.swift                  # NSApplication 부트스트랩
  AppDelegate.swift           # 메뉴, 파일 열기, 창 관리
  ViewerWindowController.swift# WKWebView + window.mdLens 브릿지 (JCEF 호스트 대체)
  RendererResources.swift     # 번들 렌더러 리소스 탐색
  Settings.swift              # 테마/프로파일 UserDefaults
resources/renderer/
  index.html                  # md-lens `npm run build:renderer` 산출물 (CSP base-uri만 file:로 패치)
  runtime-{highlight,katex,mermaid}.js  # md-lens 런타임 빌드 산출물
```

렌더러 산출물 갱신: md-lens 레포에서 `npm ci && npm run build:renderer &&
npm run build:highlight-runtime && npm run build:katex-runtime &&
npm run build:mermaid-runtime` 후 `build/generated/` 산출물을 `resources/renderer/`에
복사하고, index.html의 CSP에서 `base-uri 'none'` → `base-uri file:` 로 치환
(상대경로 이미지용 `<base>` 주입에 필요).

디버깅: `MDLENS_DEBUG_LOG=/tmp/mdlens.log` 환경변수를 주면 브릿지 이벤트를 기록한다.

## 라이선스

md-lens 및 번들 런타임(Marked, DOMPurify, github-markdown-css, Mermaid, KaTeX,
highlight.js)은 각자의 라이선스(MIT/Apache 2.0)를 따른다.
