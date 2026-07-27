# Retro Route - Development Log

> **Game:** Retro Route
>
> **Tagline:** Ride. Deliver. Relive.
>
> **Engine:** Godot 4.3
>
> **Platform:** Android (Primary), PC (Development)
>
> **Studio:** Sunset Arcade
>
> **Repository:** Private

---

# Vision

Create a polished, nostalgic 3D arcade delivery game inspired by the feeling of riding around the neighborhood as a kid.

The objective is not to recreate any existing game, but to capture the freedom, simplicity, and fun of growing up in the 90s and early 2000s.

---

# Development Principles

- Gameplay first.
- Polish over unnecessary features.
- Mobile-first design.
- Performance matters.
- Every feature must improve fun or nostalgia.
- Ship Version 1.0 before expanding.

---

# Milestones

## Pre-Production
- [x] Game concept
- [x] Game title selected
- [x] Studio name selected
- [x] Engine selected
- [x] GitHub repository created
- [ ] Game Bible completed
- [ ] Art direction finalized

---

## Alpha

- [x] Player movement
- [x] Camera system
- [ ] Bike controller
- [ ] Basic neighborhood
- [ ] Delivery system
- [ ] Score system
- [ ] Obstacles
- [ ] UI
- [ ] Audio

---

## Beta

- [ ] Character selection
- [ ] Bike unlocks
- [ ] Save system
- [ ] Settings
- [ ] Achievements
- [ ] Optimization

---

## Version 1.0

- [ ] Android App Bundle (.aab)
- [ ] Google Play Store assets
- [ ] Privacy Policy
- [ ] Release

---

# Development Log

---

## Day 1

### Completed

- Created project vision
- Chose game title **Retro Route**
- Created studio identity
- Selected Godot Engine 4.7
- Created GitHub repository
- Created Godot project
- Planned folder structure
- Defined Version 1.0 scope

### Notes

The focus for Version 1.0 is to build a polished arcade experience rather than an overly ambitious feature set. Every development decision should support a timely Play Store release.

### Next Session

- Create Main Scene
- Build player controller
- Create camera rig
- Create test environment

---

## Day 2

### Completed

- Removed the fake placeholder files that had been faking `game/` folders on `develop` (`project.godot`, `scenes`, `scripts`, `assets`, `builds` were empty 1-byte blobs, not real content).
- Created a real Godot 4.3 project under `game/` with a valid `project.godot`.
- Built the project folder structure: `assets/`, `scenes/{player,world,ui}/`, `scripts/`, `audio/`, `materials/`, `models/`, `textures/`, `fonts/`.
- Added `.gitignore` for `.godot/` cache, import artifacts, build output, and signing keys.
- Added an Android export preset (`game/export_presets.cfg`) — gradle build, arm64-v8a, min SDK 24 / target SDK 34.
- Built a minimal test scene (`scenes/world/TestScene.tscn`) with a ground plane, directional light, procedural sky, a test cube, a placeholder house (`scenes/world/House.tscn`), and a framing camera — purely to prove the project boots.
- Verified the project imports and launches cleanly under headless Godot (no display available in this environment). No parse errors, no missing resources, no script errors.

### Notes

Godot itself is not installed in the development container by default; a Godot 4.3 headless binary was downloaded to `/usr/local/bin/godot4` to validate the project. Android export templates and the Android SDK are not installed, so a real `.apk` export could not be produced — the export preset was validated as far as Godot's own configuration checks (it correctly reports missing templates/SDK, which confirms the preset file itself is well-formed).

### Next Session

- Build the real player/bike controller and hook it into `scenes/player/`.
- Build a proper chase/follow camera rig.
- Replace the placeholder house/cube test dressing with a first gray-box neighborhood block.

---

## Day 3

### Completed

- Added a `Web` export preset (`game/export_presets.cfg`) — nothreads variant (GitHub Pages can't serve the COOP/COEP headers WASM threading needs), PWA metadata enabled.
- Downloaded Godot 4.3's Web export templates and verified the `Web` preset exports successfully end to end, locally, producing a working `index.html` / `index.wasm` / `index.pck` bundle.
- Served the exported build over HTTP and drove it with headless Chromium (Playwright): confirmed it boots, initializes a WebGL2 context, and renders the test scene with **zero console/page errors**, in both a desktop viewport and an emulated mobile viewport (Pixel 7). Took a screenshot confirming the ground/cube/house scene renders correctly.
- Built `.github/workflows/deploy-web.yml`: CI builds the Web export on every push/PR touching `game/**` (checksum-verified Godot download, cached between runs), verifies the output files, and deploys to GitHub Pages on every push to `main` or manual dispatch. PRs build but don't deploy, so a broken export can't reach the live site.
- Documented the whole pipeline in `docs/DEPLOYMENT.md`, including why GitHub Pages was chosen over an alternative like Cloudflare Pages, and when that choice would need to change (custom headers for threading).

### Notes

This milestone deliberately stayed off `main`. To validate the pipeline before merge, the push trigger was temporarily widened to include this feature branch, run, then reverted — the workflow's final, committed state only triggers deploys from `main` (plus manual dispatch), exactly as required.

Two real issues surfaced and were resolved during validation:

1. GitHub Pages had never been enabled for this repo. The Actions bot token cannot create a Pages site on its own (`Resource not accessible by integration` — a deliberate GitHub security boundary), so a repo admin enabled it once via Settings → Pages → Build and deployment → Source → "GitHub Actions". Every deployment after that needs no further manual action.
2. Once Pages was enabled, `build-web` and the Pages setup/artifact-upload steps ran fully green from this branch — but the final `deploy` step correctly declined to run, because GitHub's own `github-pages` environment protection rules restrict deployment to `main` by default. That's the correct production behavior, not a bug, and it will fire automatically the moment this branch is merged.

### Next Session

- Merge this branch into `main` (after approval) and confirm the first automatic `main`-triggered deployment goes green, producing the live URL.
- Build the real player/bike controller and hook it into `scenes/player/`.
- Build a proper chase/follow camera rig.

---

## Day 4

### Completed

- Built the first playable prototype: full third-person arcade locomotion (walk/run/accelerate/decelerate/momentum/air control), an arcade jump with variable height and landing detection, and a smooth auto-follow chase camera with collision avoidance.
- Built the input abstraction (`PlayerInput`) so keyboard and on-screen touch controls are indistinguishable to the locomotion code — the same contract a future BMX controller will reuse.
- Built the mobile touch UI from scratch (no external image assets): an analog virtual joystick and a round jump button, both drawn via `_draw()` and handling real multitouch by tracking pointer/touch index.
- Added visual polish: placeholder capsule character with a facing indicator, a raycast blob shadow that fades with jump height, lightweight movement dust particles, and a squash/stretch landing bounce.
- New main scene: `scenes/world/Playground.tscn`, replacing `TestScene.tscn` as `run/main_scene` (which is kept as-is for boot verification).
- Deployed the milestone to the Web build pipeline built last session and verified it live.

### Notes

Two real bugs were caught and fixed during testing, both worth remembering:

1. **Touch-coordinate scaling.** My first touch-simulation test appeared to do nothing — the joystick never activated. Root cause: the project's base viewport was still `1280x720` (landscape) from the foundation milestone, but this is a portrait, mobile-first game. Godot's `canvas_items` + `expand` stretch mode picks a uniform scale so the *narrower* base dimension matches the window, and expands the other logical dimension to fill the rest — on a portrait phone window against a landscape base, that inflated the logical canvas far beyond the window's real pixel size, so screen-space touch coordinates landed nowhere near the anchored UI. Fixed by swapping the base viewport to `720x1280` (portrait), which also fixed the touch controls rendering noticeably too small on-screen.
2. **`Basis must be normalized` runtime error.** The player's facing rotation was applied by overwriting `visual_root.global_transform.basis` directly every frame, while the squash-stretch landing feedback animated the *same node's* `scale` — both features are ultimately stored in the same `transform.basis` matrix in Godot 4, so they fought each other and drifted out of orthonormality. Fixed by driving facing (and the camera rig's yaw) through a smoothed scalar angle applied via the dedicated `rotation.y` property instead of reassigning the whole basis, which composes cleanly with `scale` and can't drift.

Testing methodology: rather than trust manual inspection, physics behavior was verified with headless SceneTree scripts that simulate real input and assert on position/velocity/state (gravity settle, camera-relative movement direction and speed, held-jump height vs. tap-jump height, landing state transitions). Touch controls were verified against the actual exported Web build using genuine synthetic `Touch`/`TouchEvent` objects dispatched at the canvas (not mouse emulation), with before/after screenshots as visual proof alongside a zero-console-error check.

### Next Session

- Build the first gray-box neighborhood block to replace the placeholder cube/house test dressing.
- Begin planning the BMX locomotion variant that will replace (not discard) this milestone's movement tuning.

---

# Current Version

v0.0.4 (Alpha — First Playable Prototype)

---

# Known Issues

- No Android export templates or Android SDK installed in the current dev environment, so the Android export preset is untested end-to-end (project-side configuration only). Android is not yet part of the CI/CD pipeline.
- Running the project under `--headless` (no GPU/display) logs a benign `mesh_get_surface_count` "Parameter m is null" error per `MeshInstance3D` — this is a known artifact of Godot's dummy rendering driver used for headless validation and does not occur with a real display/GPU or in the exported Web build (confirmed clean in an actual browser).
- WASM multithreading is disabled in the Web export preset because GitHub Pages cannot serve the `Cross-Origin-Opener-Policy` / `Cross-Origin-Embedder-Policy` headers it requires. Not a problem today; would need Cloudflare Pages (or similar) if threading becomes necessary later.
- The camera has no dedicated look input by design (mobile controls are movement + jump only) — it auto-orients behind the player's facing direction. This matches the intended mobile-first UX but means there's currently no way to look around independently of moving.
- Concurrent multitouch (dragging the joystick while tapping jump) relies on Godot's native browser touch handling, which is well-established engine behavior; it was exercised sequentially in automated testing rather than via a hand-crafted concurrent synthetic touch sequence, since accurately simulating true concurrent multitouch through raw DOM events is significantly more complex than the engine behavior it would be verifying.

---

# Backlog

- Weather system
- Seasonal maps
- Additional neighborhoods
- BMX customization
- Endless Mode
- Daily challenges
- Holiday events

---

# Motto

> Build. Test. Improve. Ship.
