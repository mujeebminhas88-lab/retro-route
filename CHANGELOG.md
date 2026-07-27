# Changelog

All notable changes to Retro Route will be documented in this file.

## [Unreleased]

### Milestone: First Playable Prototype (Locomotion)

- Built the player locomotion system as a reusable foundation (`game/scripts/player/player.gd`, class `Player`, `CharacterBody3D`): grounded walk/run with acceleration/deceleration/momentum, reduced-strength air control, camera-relative movement direction, and a small grounded/airborne state machine — designed so the planned BMX locomotion replaces the tuning values, not the architecture.
- Arcade jump: exported `jump_height`/`jump_time_to_peak`/`jump_time_to_descend` drive analytically-derived rise/fall gravity; holding jump gives full height, releasing early cuts it short (variable jump height); landing is edge-detected from the pre-move `velocity.y` and drives visual feedback.
- Added `game/scripts/player/player_input.gd` (`PlayerInput`): a stateless static helper that merges keyboard input and the on-screen touch controls into one query contract (`get_move_vector`, `get_speed_scale`, `get_jump_just_pressed`, `get_jump_held`), so any future input source (or BMX steering) reuses the same contract.
- Added `game/scripts/camera/follow_camera.gd` (`FollowCamera`): a `SpringArm3D`-based smooth third-person chase camera that auto-orients behind the player's current facing (no dedicated look stick, matching the touch control layout), with adjustable follow distance, position/rotation smoothing, and built-in collision avoidance via the spring arm's shape cast.
- Added the mobile touch control surface: `game/scripts/ui/virtual_joystick.gd` (analog stick, drag-anywhere tracking by touch/mouse index, dead zone) and `game/scripts/ui/touch_button.gd` (round tap button), orchestrated by `game/scripts/ui/touch_controls.gd` (`TouchControls`). Both keyboard and touch/mouse work simultaneously without double-handling.
- Visual polish: a placeholder capsule+head character with a facing indicator (`game/scenes/player/Player.tscn`), a raycast-follower "blob shadow" that fades with height (`game/scripts/effects/ground_shadow.gd`), a lightweight `GPUParticles3D` movement-dust emitter (`game/scripts/effects/dust_emitter.gd`), and a squash/stretch landing-feedback tween (`game/scripts/effects/squash_stretch.gd`). A shared soft-circle gradient texture is generated once and reused for both the shadow and dust materials.
- New scenes: `game/scenes/player/Player.tscn`, `game/scenes/player/CameraRig.tscn`, `game/scenes/ui/TouchControls.tscn`, and `game/scenes/world/Playground.tscn` (the new main scene — ground/sky/lighting plus the player, camera rig, and touch UI wired together via scene-unique-name `NodePath`s). `TestScene.tscn` from the foundation milestone is untouched and still exists as a minimal boot check.
- Added keyboard input actions (`move_forward/back/left/right`, `jump`, `walk_modifier`) to the project's input map.
- Fixed the project's base viewport to a portrait resolution (`720x1280`, was `1280x720`) to match the mobile-first/portrait design — the previous landscape base caused Godot's `canvas_items` + `expand` stretch mode to render on-screen touch controls noticeably smaller than intended on portrait phone screens.
- Fixed a rotation/scale conflict: the player's facing rotation and its squash-stretch scale animation were both applied to the same node's `global_transform.basis`, which are two different underlying transform representations. Facing is now driven by a smoothed scalar yaw applied via the dedicated `rotation.y` property (same fix applied to the camera rig's yaw), which resolved a recurring `Basis must be normalized` runtime error and eliminates a class of long-session floating-point drift.
- Verified extensively: a battery of headless physics simulations (gravity/settle, forward/strafe/back movement with correct camera-relative direction, held-jump reaching ~1.35m against a 1.4m target, tap-jump producing a distinctly shorter hop, landing detection) with zero runtime errors; and a real Web export driven with headless Chromium using genuine synthetic `Touch`/`TouchEvent`s (not mouse emulation) confirming the joystick drag, release, and jump button all work correctly end-to-end, with dust particles, ground shadow height-fade, and jump/landing all visible in captured screenshots and zero console/page errors.

### Milestone: Continuous Deployment (Web)

- Added a `Web` export preset to `game/export_presets.cfg` (nothreads variant, since GitHub Pages cannot serve the COOP/COEP headers required for WASM threads; PWA metadata enabled).
- Added `.github/workflows/deploy-web.yml`: a two-job GitHub Actions pipeline that builds the Godot Web export on every push/PR touching `game/**`, verifies the output, uploads it as a workflow artifact, and deploys it to GitHub Pages on every push to `main` (or manual dispatch). Pull requests build but never deploy.
- Godot editor + Web export templates are downloaded with pinned versions and SHA-512 checksum verification, and cached between CI runs.
- Added `docs/DEPLOYMENT.md` documenting the pipeline, the GitHub Pages choice (and the Cloudflare Pages fallback if custom headers are ever needed for threading), how to trigger deployments, and how to reproduce the build locally.
- Verified locally end-to-end: downloaded Godot 4.3 editor + Web export templates, ran the exact import/export commands the CI workflow runs, and confirmed the exported build boots and renders (WebGL2, no console/page errors) in both a desktop viewport and an emulated mobile viewport (Pixel 7) via headless Chromium, with a rendered screenshot confirming the ground/cube/house scene displays correctly.
- Verified in CI on this branch (via temporary manual dispatch, since branch-only runs otherwise can't test a `main`-gated deploy step): the full `build-web` job (checksum-verified download, import, export, output verification, artifact upload) and Pages setup/artifact-upload steps ran green. GitHub Pages was enabled on the repo (a one-time admin action the Actions token intentionally can't do itself). The final `deploy` step correctly declined to run from a non-`main` branch due to GitHub's own `github-pages` environment protection rules — the intended production behavior. It will run automatically on the next push to `main`.
- Live URL (activates on the first deploy from `main`, i.e. once this branch is merged): `https://mujeebminhas88-lab.github.io/retro-route/`

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
