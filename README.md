# MarkView

GitHub 스타일로 렌더링하는 네이티브 macOS 마크다운 뷰어.
코드 하이라이트, Mermaid 다이어그램, KaTeX 수식, GitHub 알림·각주·태스크 리스트를 지원한다.

## 빌드

```bash
./make-app.sh    # → MarkView.app
```

## 사용

- `open -a "$PWD/MarkView.app" some.md` 또는 Finder에서 "다음으로 열기"
- Cmd-O 로 파일 열기, 여러 창 지원
- 파일 변경 시 자동 리로드 (에디터의 atomic save 포함)
- `.md` `.markdown` `.mdown` `.mmd` `.mermaid` 지원 — `.mmd`는 단독 Mermaid 문서로 렌더링

## View 메뉴

| 항목 | 값 |
|---|---|
| Theme | System / Light / Dark |
| Style | GitHub / LaTeX / Tufte |
| Profile | Compact / Spacious |
| Font | Default(시스템) + 설치된 추천 폰트 |
| Content Width | 768–1536px / Full Width |
| Accent Colors | Headings·Bold·Inline Code 각각 Off + 8색 |
| 글자 크기 | Cmd +/-/0 (12–24px) |

## 구조

```
Sources/MarkView/
  App/           # 부트스트랩, AppDelegate, 메뉴 구성
  Domain/        # 외관 설정 모델, 렌더 요청 모델
  Rendering/     # WKWebView 렌더러 호스트, 번들 에셋 탐색
  Presentation/  # 문서 뷰어 창
  Support/       # 파일 감시, 디버그 로그
resources/
  renderer/      # 렌더링 엔진 (사전 빌드 산출물)
  skins/         # LaTeX·Tufte 스타일 CSS
```

서드파티 고지는 앱의 About 패널(Credits)에 포함된다.

디버깅: `MARKVIEW_DEBUG_LOG=/tmp/markview.log` 환경변수를 주면 브릿지 이벤트를 기록한다.
