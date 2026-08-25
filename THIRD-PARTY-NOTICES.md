# Third-Party Notices

MarkView bundles a prebuilt markdown rendering engine in `resources/renderer/`.
These artifacts are built from the following open-source projects and remain
under their original licenses. This notice must be retained in distributions.

## Renderer

- **md-lens** — MIT License
  Copyright (c) Hyune-s-lab
  https://github.com/Hyune-s-lab/md-lens

  `resources/renderer/index.html` and `runtime-*.js` are build outputs of the
  md-lens renderer (v0.4.0), with two local patches:
  CSP `base-uri 'none'` → `base-uri file:`, and viewer placeholder/title text.

  Regenerating the artifacts: in an md-lens checkout run
  `npm ci && npm run build:renderer && npm run build:highlight-runtime &&
  npm run build:katex-runtime && npm run build:mermaid-runtime`,
  copy `build/generated/**` outputs into `resources/renderer/`,
  then re-apply the patches above.

## Bundled runtime dependencies

| Project | License |
|---|---|
| Marked | MIT |
| marked-footnote | MIT |
| DOMPurify | Apache-2.0 |
| github-markdown-css | MIT |
| highlight.js | BSD-3-Clause |
| KaTeX | MIT |
| Mermaid | MIT |
| Material Design Icons | Apache-2.0 |

Full license texts are available in each project's repository.
