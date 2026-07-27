# Changelog

All notable changes to Retro Route will be documented in this file.

## [Unreleased]

### Milestone: The BMX Begins (First Arcade BMX Prototype)

- Replaced the walk/run locomotion in `game/scripts/player/player.gd` with arcade BMX vehicle controls: forward/back is throttle/brake, left/right steers the bike. No wheel colliders, no suspension, no gear shifting, no manual balancing — tuned purely for immediate, responsive, Paperboy-style fun, not simulation.
- Every tuning value is an exported `@export` parameter, per the milestone requirement: `top_speed`, `reverse_speed_ratio`, `acceleration`, `braking`, `steering_sensitivity`, `turning_radius`, `min_turn_speed`, plus optional visual-feel knobs `lean_angle_max_degrees`, `pitch_angle_max_degrees`, `lean_response`, `wheel_spin_rate`.
- The player now spawns already mounted on the bike — there's no separate "get on the BMX" step or state; BMX riding *is* the game's only locomotion mode.
- Steering angular velocity scales with current speed (`(speed / turning_radius) * steering_sensitivity`, floored by `min_turn_speed` so a light throttle still lets the bike pivot instead of feeling stuck) — the closest arcade approximation of "you can't turn sharply at a standstill" without any real bicycle physics.
- Added subtle, tunable visual polish — speed-scaled lean into turns, a small forward/back pitch under acceleration/braking, and spinning wheels — applied to a new `LeanPivot` child node instead of `VisualRoot` itself, so it can never corrupt the `VisualRoot.global_transform.basis.z` facing vector that `FollowCamera` and `Thrower` both depend on (the same transform-isolation lesson learned from Milestone 4's squash-stretch bug).
- Rebuilt `game/scenes/player/Player.tscn`: the placeholder character now sits atop simple primitive BMX geometry (two spinning wheels, a frame, a handlebar — `TorusMesh`/`BoxMesh`, matching the existing low-poly placeholder art style). Collision stays the existing capsule; no new colliders were added.
- Reused the existing chase camera and gravity/jump/landing state machine entirely unchanged — only the horizontal movement model changed.
- Removed `PlayerInput.get_speed_scale()` (the walk/run blend helper), which became dead code once BMX throttle replaced the walk/run speed lerp.
- A real steering bug was found and fixed during testing: the initial implementation turned the bike *left* when steering right (and vice versa). Caught by comparing the new steering math against the sign convention `Basis.looking_at()` uses (and the pre-BMX locomotion relied on) for "facing +X is a negative `rotation.y`" — confirmed with a live browser session before the fix (bike visibly turned the wrong way) and after (correct).
- Verified extensively: a headless scripted test drives the real `Playground` scene end-to-end — accelerates to top speed, brakes back to a stop, confirms steering turns the bike, then rides toward the active mailbox and throws while still moving, asserting the score lands on exactly 10. In the real exported Web build, closed-loop pursuit sessions (reading live player/target position through a temporary debug bridge, removed before commit) delivered successfully with both genuine keyboard input and genuine synthetic touch events, both reaching **Score: 10** with **zero console/page errors**.

## [v0.1.0-alpha] - 2026-07-27

First production release. Promotes the approved work from Milestones 1-5 (project foundation, continuous deployment, first playable locomotion, first complete gameplay loop) to `main` and to the public Web deployment. See the milestone sections below for full detail; summary:

- A real, working Godot 4.3 project (previously the repo only had placeholder files).
- An automated Web build pipeline: every push to `main` builds, verifies, and deploys to GitHub Pages.
- A polished third-person arcade locomotion system (walk/run/jump/camera) usable from both keyboard and mobile touch controls.
- A complete, replayable core gameplay loop: throw newspapers at an auto-targeted mailbox, deliver, score, repeat.

**Live URL:** https://mujeebminhas88-lab.github.io/retro-route/

### Milestone: First Complete Gameplay Loop (Deliveries)

- Added the delivery gameplay loop: throw newspapers at an auto-targeted active mailbox, score on hit, next mailbox activates automatically.
- `game/scripts/gameplay/newspaper.gd` (`Newspaper`): kinematic (non-physics) arc projectile. Hit/miss is decided once at launch time from throw distance vs. a max range, not from runtime collision — deterministic, easy to follow, and cheap. `launch()` takes an explicit target position so a future manual-aim mode only changes target selection, not this class.
- `game/scripts/gameplay/mailbox.gd` (`Mailbox`): delivery target with an active/inactive visual state (glowing bobbing flag + a gold ground target-ring reusing the Milestone 4 soft-circle texture), a `DeliveryPoint` marker, and a `play_delivered_feedback()` that reuses `SquashStretch` (from the player) plus a one-shot particle burst.
- `game/scripts/gameplay/delivery_manager.gd` (`DeliveryManager`): single source of truth for score and the active-mailbox rotation. Discovers mailboxes via the `"mailboxes"` group (add a `Mailbox` to the scene and the group, no manual wiring needed), shuffles delivery order, and orchestrates score increment, floating "+10" popup, a procedurally-generated two-note success chime, and mailbox feedback on every delivery.
- `game/scripts/gameplay/thrower.gd` (`Thrower`): a `Player` child node that reads the unified `PlayerInput.get_throw_just_pressed()` contract (same pattern as jump) and spawns a `Newspaper` toward `DeliveryManager.get_active_mailbox()`.
- `game/scripts/effects/floating_popup.gd` (`FloatingPopup`): reusable world-space floating text (Label3D) that rises and fades, used for the "+10" score popup.
- `game/scripts/ui/hud.gd` (`HUD`): minimal HUD — score label and a "Delivery Complete!" flash — purely reactive to `DeliveryManager` signals, no gameplay logic of its own.
- Added a dedicated `throw` input action (keyboard `F`) and a third on-screen touch button (`THROW`, alongside `JUMP`), both routed through `PlayerInput`/`TouchControls` using the same contract pattern established for jump.
- Added a visible newspaper stack prop near spawn and three `Mailbox` instances placed around the playground (`game/scenes/world/Playground.tscn`), each in the `"mailboxes"` group.
- New scenes: `game/scenes/world/{Mailbox,Newspaper}.tscn`, `game/scenes/ui/{FloatingPopup,HUD}.tscn`; `game/scenes/ui/TouchControls.tscn` updated with the throw button.
- Two real bugs found and fixed during testing:
  1. `Thrower`/`DeliveryManager` spawned newspapers and score popups via `get_tree().current_scene`, which is only reliably set by Godot's normal scene-load flow — it was `null` in a headless test harness. Fixed by spawning as a sibling of the player / child of the delivery manager instead, which works regardless of how the scene was loaded.
  2. The default throw range (7.0) put every mailbox already in range from the player's spawn point, trivializing the intended "walk to the target" loop. Reduced to 4.5, which requires real movement while staying comfortable once near the active mailbox.
- Verified extensively: a headless scripted test asserts score stays 0 on a from-spawn miss, becomes exactly 10 on a close-range hit, and that a *different* mailbox becomes active afterward. In the real exported Web build, driven with genuine keyboard input, a full wander-and-throw session reached **Score: 10**; with genuine synthetic touch events (joystick + throw button), a sustained-direction session reached **Score: 30** (three deliveries) — both with **zero console/page errors**.

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
