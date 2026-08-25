# MarkView

GitHub 스타일로 렌더링하는 네이티브 macOS 마크다운 뷰어.
GitHub Light/Dark 테마, 코드 하이라이트, Mermaid 다이어그램, KaTeX 수식,
GitHub 알림·각주·태스크 리스트를 지원한다.

## 빌드

```bash
./make-app.sh    # → MarkView.app
```

## 사용

- `open -a "$PWD/MarkView.app" some.md` 또는 Finder에서 "다음으로 열기"
- Cmd-O 로 파일 열기, 여러 창 지원
- 파일 변경 시 자동 리로드 (에디터의 atomic save 포함)
- View 메뉴: Theme (System/Light/Dark), Profile (Compact/Spacious), 글자 크기 (Cmd +/-/0)
- `.md` `.markdown` `.mdown` `.mmd` `.mermaid` 지원 — `.mmd`는 단독 Mermaid 문서로 렌더링

## 구조

```
Sources/MarkView/
  App/           # 부트스트랩, AppDelegate, 메뉴 구성
  Domain/        # 외관 설정 모델, 렌더 요청 모델
  Rendering/     # WKWebView 렌더러 호스트, 번들 에셋 탐색
  Presentation/  # 문서 뷰어 창
  Support/       # 파일 감시, 디버그 로그
resources/renderer/
  index.html, runtime-{highlight,katex,mermaid}.js   # 렌더링 엔진 (사전 빌드 산출물)
```

렌더링 엔진의 출처·라이선스·재생성 절차는 [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) 참조.

디버깅: `MARKVIEW_DEBUG_LOG=/tmp/markview.log` 환경변수를 주면 브릿지 이벤트를 기록한다.
