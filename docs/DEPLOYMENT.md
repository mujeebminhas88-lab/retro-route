# Deployment Pipeline

Retro Route ships a **Web (HTML5) build** on every change to `main`, so any
milestone can be played instantly on a phone or desktop by opening a URL —
no build tools, no install, no APK sideloading required.

## Live URL

```
https://mujeebminhas88-lab.github.io/retro-route/
```

This URL becomes live the first time this workflow deploys from `main`
(GitHub Pages needs one successful deployment to provision the site). It
always serves whatever was most recently pushed to `main`.

## How it works

```
push to main / workflow_dispatch
        │
        ▼
┌───────────────────────┐
│ build-web job          │
│  - checkout repo       │
│  - fetch Godot 4.3     │  (cached after first run; checksum-verified)
│    editor + Web        │
│    export templates    │
│  - import assets       │
│  - export "Web" preset │
│  - verify output files │
│  - upload as artifact  │
└───────────┬────────────┘
            │ (skipped for pull_request events)
            ▼
┌───────────────────────┐
│ deploy job             │
│  - actions/deploy-pages│
│    publishes the build │
│    to GitHub Pages     │
└───────────────────────┘
```

The pipeline lives in [`.github/workflows/deploy-web.yml`](../.github/workflows/deploy-web.yml)
and has two jobs:

1. **`build-web`** — runs on every push to `main`, every pull request into
   `main`, and on manual `workflow_dispatch`. It downloads a pinned,
   checksum-verified Godot 4.3 headless editor and the Web export
   templates (cached between runs via `actions/cache`), imports the
   project's assets, runs the `Web` export preset defined in
   `game/export_presets.cfg`, and verifies the expected output files
   (`index.html`, `index.js`, `index.wasm`, `index.pck`) exist and are
   non-empty. If the export fails or produces incomplete output, the job
   fails and the run is marked red — that's the build-failure detector.
   The build output is also uploaded as a downloadable workflow artifact
   for 14 days, useful for debugging a red build without redeploying.

2. **`deploy`** — only runs for pushes to `main` and manual dispatches
   (pull requests build but never deploy, so a broken PR can never reach
   the live site). It publishes the exported `builds/web/` directory to
   GitHub Pages using GitHub's official `actions/deploy-pages` action.

## Why GitHub Pages (and not an alternative)

GitHub Pages was used because it required no new accounts, no extra
secrets, and no third-party dependency — it deploys straight from the
repository's own Actions permissions (`pages: write`, `id-token: write`),
and Godot's Web export is static (no server-side code), which is exactly
what Pages serves. No technical blocker was hit that would require an
alternative like Cloudflare Pages; if one arises later (e.g. needing
custom HTTP headers for `SharedArrayBuffer`/multithreading — see below),
Cloudflare Pages is the recommended fallback since it supports a
`_headers` file for that.

## A note on threads and `SharedArrayBuffer`

Godot's Web export can optionally use multithreading via WebAssembly
threads, which requires the page to be served with
`Cross-Origin-Opener-Policy: same-origin` and
`Cross-Origin-Embedder-Policy: require-corp` response headers.
**GitHub Pages cannot set custom response headers on static files.**
Because of this, the `Web` export preset has thread support disabled
(`variant/thread_support=false`, exporting the `nothreads` template
variant), so the game runs correctly on GitHub Pages without those
headers. This is also the safer default for low/mid-range mobile
browsers. If multithreading is needed later, moving to Cloudflare
Pages (which supports a `_headers` file) or fronting Pages with a
service worker that injects those headers would be the path forward.

## How to trigger a deployment

- **Automatic:** merge or push to `main`. The workflow builds and deploys
  within a few minutes.
- **Manual:** run the "Build and Deploy Web" workflow from the Actions tab
  (`workflow_dispatch`), or via the GitHub CLI/API, from any branch — useful
  for testing the pipeline itself before merging.

## Local reproduction

The CI steps can be run locally with a headless Godot 4.3 binary:

```bash
godot4 --headless --path game --import
mkdir -p builds/web
godot4 --headless --path game --export-release "Web" ../builds/web/index.html
# Serve it locally to test in a browser (Godot Web builds require http(s), not file://):
cd builds/web && python3 -m http.server 8060
```

## Known limitations

- The Android export preset (`game/export_presets.cfg`, preset `Android`)
  is configured but **not** part of this pipeline yet — Android builds
  need the Android SDK/NDK and signing keys, which is a larger, separate
  piece of CD work for a later milestone.
- The Godot editor/template download step re-downloads (~1 GB) on a cache
  miss (e.g. after the cache expires or the pinned version changes). This
  is expected and only affects the first run after a cache invalidation.
