# Changelog

All notable changes to Retro Route will be documented in this file.

## [Unreleased]

### Milestone: Continuous Deployment (Web)

- Added a `Web` export preset to `game/export_presets.cfg` (nothreads variant, since GitHub Pages cannot serve the COOP/COEP headers required for WASM threads; PWA metadata enabled).
- Added `.github/workflows/deploy-web.yml`: a two-job GitHub Actions pipeline that builds the Godot Web export on every push/PR touching `game/**`, verifies the output, uploads it as a workflow artifact, and deploys it to GitHub Pages on every push to `main` (or manual dispatch). Pull requests build but never deploy.
- Godot editor + Web export templates are downloaded with pinned versions and SHA-512 checksum verification, and cached between CI runs.
- Added `docs/DEPLOYMENT.md` documenting the pipeline, the GitHub Pages choice (and the Cloudflare Pages fallback if custom headers are ever needed for threading), how to trigger deployments, and how to reproduce the build locally.
- Verified locally end-to-end: downloaded Godot 4.3 editor + Web export templates, ran the exact import/export commands the CI workflow runs, and confirmed the exported build boots and renders (WebGL2, no console/page errors) in both a desktop viewport and an emulated mobile viewport (Pixel 7) via headless Chromium, with a rendered screenshot confirming the ground/cube/house scene displays correctly.
- Live URL (activates on first deploy from `main`): `https://mujeebminhas88-lab.github.io/retro-route/`

### Milestone: Project Foundation

- Removed the fake placeholder files (`game/project.godot`, `game/scenes`, `game/scripts`, `game/assets`, `builds`) that had been created as empty stand-ins for folders on the `develop` branch and were never real project content.
- Created a real Godot 4.3 project at `game/` with a valid `project.godot` (Mobile rendering method, Android-friendly display defaults, portrait orientation).
- Established the project folder structure:
  - `game/assets/`
  - `game/scenes/player/`, `game/scenes/world/`, `game/scenes/ui/`
  - `game/scripts/`
  - `game/audio/`
  - `game/materials/`
  - `game/models/`
  - `game/textures/`
  - `game/fonts/`
- Added a repository-wide `.gitignore` covering Godot's `.godot/` cache, import artifacts, build output (`builds/`, `*.apk`, `*.aab`), and Android signing keys.
- Added an Android export preset (`game/export_presets.cfg`) targeting arm64-v8a, gradle build, min SDK 24 / target SDK 34.
- Added a placeholder app icon (`game/icon.svg`).
- Created a minimal playable test scene (`game/scenes/world/TestScene.tscn`) to verify the project boots correctly:
  - Ground plane with collision
  - `DirectionalLight3D` with shadows
  - `WorldEnvironment` with a procedural sky
  - One test cube with collision
  - One placeholder house scene (`game/scenes/world/House.tscn`), instanced into the test scene
  - A static `Camera3D` framing the scene
- Verified the project imports and launches without errors via headless Godot (`godot4 --headless --path game --quit-after 60`).
- Brought the real planning docs (`docs/DEVLOG.md`, `docs/GAME_BIBLE.md`, `docs/ROADMAP.md`) over from the `develop` branch, which previously held real content stranded on an unmerged branch.
