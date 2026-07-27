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
- [x] Bike controller
- [x] Basic neighborhood
- [x] Delivery system
- [x] Score system
- [ ] Obstacles
- [x] UI
- [x] Audio

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

## Day 5

### Completed

- Built the first complete gameplay loop: throw newspapers at an auto-targeted mailbox, deliver, score, next mailbox activates, repeat. This is the first genuinely *playable* (not just controllable) build.
- Newspaper flight is deterministic and kinematic (sine-arc lerp, not physics) — hit/miss decided once at throw time from distance vs. range, which keeps delivery reliable and the arc easy to read, while still leaving room for manual aiming later (only the target-selection step would change).
- `DeliveryManager` centralizes score and active-mailbox rotation; mailboxes only know how to look active/inactive and play their own bounce+particle feedback, keeping the pieces independently reusable.
- Reused two Milestone 4 systems directly instead of writing new ones: `SquashStretch` for the mailbox's delivery bounce, and the soft-circle gradient texture for the mailbox's gold target ring (same technique as the ground shadow).
- Added a third touch button (THROW) next to JUMP, and a `throw` keyboard action, both going through the same `PlayerInput` contract as jump.
- Procedurally generated a short two-note success chime at build time (no external audio asset) for the delivery sound.

### Notes

Two real bugs surfaced during testing:

1. `get_tree().current_scene` was `null` in a headless test harness (it's only set by Godot's normal scene-load flow, not by manually adding a scene under the root) — `Thrower` and `DeliveryManager` used it to spawn newspapers and score popups. Fixed by spawning relative to existing node references (the player's parent, the delivery manager itself) instead, which works regardless of how the scene was loaded — more robust in general, not just for tests.
2. The default throw range (7.0) meant every mailbox was already in range from the player's spawn point — a throw would always succeed without ever moving, defeating the point of the loop. Caught by a headless test that expected a spawn-point throw to miss and got a hit instead. Tuned down to 4.5.

Also confirmed (not a bug, just worth recording): holding a single non-forward direction (e.g. "left" alone) against the auto-follow camera causes the character to curve/spiral rather than travel in a straight line, because the camera continuously re-centers behind the player's changing facing while movement is interpreted relative to the camera. Holding "forward" alone is a stable straight line. This is an inherent property of the camera-relative auto-follow design approved in Milestone 4, not a defect — noted here because it shaped how the automated browser tests had to move the player (sustained mostly-forward drags beat alternating/circular sweeps).

Testing: a headless scripted test asserts score stays 0 on a from-spawn miss, becomes exactly 10 on a close-range hit, and a different mailbox goes active afterward. In the real exported Web build: a keyboard-driven session (move + throw, no debugging aids) reached **Score: 10**; a touch-driven session (synthetic joystick drags + throw-button taps) reached **Score: 30** (three deliveries). Both had **zero console/page errors**.

### Next Session

- Build the first gray-box neighborhood block.
- Consider a subtle on-screen directional cue (e.g. an off-screen arrow) toward the active mailbox now that there are three spread around the map — the gold target ring is only visible once it's in view.

---

## Day 6

### Completed

- Replaced walking with the first arcade BMX prototype ("The BMX Begins" milestone), following v0.1.0-alpha's release to `main`. Vehicle-style controls: forward/back is throttle/brake, steering turns the bike — no wheel colliders, no suspension, no gear shifting, no manual balancing, by design. This is arcade fun (Paperboy-style), not a bicycle simulation.
- Every movement tuning value is exported (`top_speed`, `reverse_speed_ratio`, `acceleration`, `braking`, `steering_sensitivity`, `turning_radius`, `min_turn_speed`, plus visual-feel knobs), not hard-coded, per the milestone brief.
- The player now spawns already mounted — riding the BMX is the only locomotion mode, there's no separate mount/dismount step.
- Added subtle speed-scaled lean, pitch, and wheel spin, all on a new `LeanPivot` child kept deliberately separate from `VisualRoot` so it can never interfere with the facing vector the camera and throwing system read.
- Rebuilt the player scene with simple primitive bike geometry (frame, handlebar, two spinning wheels) sitting under the existing placeholder character; camera, gravity, jump, and the whole delivery gameplay loop were left untouched and required no changes beyond the movement source.

### Notes

One real bug, caught before it shipped: the first version of the steering math turned the bike the *wrong* way — pressing right turned it left. It wasn't obvious from reading the code; it only showed up once a live browser test tried to steer toward a specific mailbox and the bike visibly curved away instead. Traced it to a sign mismatch against the `Basis.looking_at()` convention the rest of the game already relies on (facing world +X corresponds to a *negative* `rotation.y`) and fixed the one sign in `_update_steering`.

Testing needed a different trick than previous milestones. The old camera-relative locomotion could be driven open-loop (just hold a direction and it goes that way); a vehicle-style controller can't — a blind "drive forward and hope" script either circles too tightly (full-lock steering always resolves to the same ~1.6m circle radius regardless of speed, an interesting side effect of the turning formula) or overshoots the whole 60m map in a couple of seconds at top speed. Two things made this tractable: a scripted headless test that reads and asserts on the real `Player` node's state frame-by-frame (acceleration, braking, steering angle, and a full ride-while-throwing delivery), and, for the real exported Web build, a temporary debug bridge (removed before commit) that exposed live position/heading to the browser test so it could steer toward the actual active mailbox instead of guessing blind. Both a genuine keyboard session and a genuine synthetic-touch session delivered successfully (Score: 10) with zero console errors.

### Next Session

- Build the first gray-box neighborhood block for the bike to actually ride through.
- Revisit the on-screen directional cue toward the active mailbox — more noticeable now that the bike covers ground faster than walking did.

---

## Day 7

### Completed

- Merged Milestone 6 (BMX) to `main`, confirmed CI + Pages deploy green, then built Milestone 7 ("The First Neighborhood") on its own branch: replaced the prototype test playground with the first real suburban street.
- Built a 13-piece reusable modular kit (`game/scenes/world/props/`) — road, sidewalk, and curb segments; a driveway; a road-marking dash; a tree; a bush; a streetlight; a telephone pole; a fire hydrant; a bench; a trash bin; a fence segment — all simple low-poly primitives in bright, flat, readable colors, matching the placeholder character's art style.
- Assembled a straight two-sided street: 5 tiled road/sidewalk/curb segments (60m), a dashed yellow center line, 6 houses (3 per side) each with its own driveway, mailbox, and a bush, 6 trees, 4 streetlights, 2 telephone poles, 2 fire hydrants, a bench, 2 trash bins, and picket fences around the two front yards nearest spawn. Front lawns are just the existing grass ground plane — road/sidewalk/driveway pieces are thin non-colliding overlays on one continuous flat collision floor, so there's no seam anywhere the bike can get stuck, and no new collision complexity for the road network itself.
- The whole neighborhood renders in **135 draw calls** in the real exported Web build — comfortably lightweight for mobile, with plenty of headroom before any instancing/batching optimization would be worth it.
- Camera, gravity/jump/landing, and the entire delivery gameplay loop needed zero changes — `DeliveryManager` picked up all 6 new mailboxes automatically via the existing `"mailboxes"` group.

### Notes

Two real bugs surfaced while writing the headless builder script that assembles the neighborhood into `Playground.tscn` (load the scene, rebuild its dressing in code, re-save — the same pattern used for the Milestone 6 BMX scene rebuild):

1. Recursively reassigning `owner` on an *instanced* sub-scene's internal children (e.g. a placed `Mailbox`'s `VisualRoot/Flag`) flattens and duplicates that scene's node tree when saved, instead of keeping it as a clean `instance=ExtResource(...)` reference — which corrupted `@onready $Path` lookups (`flag_mesh` came back null) the moment the scene was reloaded. The fix is narrower than it sounds: only the instance *root* should ever get its `owner` reassigned when placing it into an outer scene; its own descendants already belong to their own referenced scene and must be left alone.
2. Godot readies sibling nodes in child-index order. The newly-appended `Mailbox` nodes ended up positioned after `DeliveryManager` in the tree (new nodes are appended; `DeliveryManager` kept its original earlier position from before the rebuild), so `DeliveryManager._ready()` — which immediately activates a mailbox — ran before that mailbox's own `_ready()` had resolved its child references, crashing on a null `flag_mesh`. Fixed by explicitly moving `DeliveryManager` to be the last child once the neighborhood is fully built.

A third thing was a test-harness quirk, not a gameplay bug: inside a custom headless `SceneTree` test script, group membership (`get_nodes_in_group`) and anything that depends on other nodes' `_ready()` isn't reliably queryable synchronously inside `_init()` — it only settles by the first `_process()` frame. Structural assertions (mailbox count, house count) had to move from `_init()` into the first `_process()` tick. This doesn't affect the shipped game at all — the real Web build boots through Godot's normal scene-load flow, not a hand-rolled `add_child()` — but it's worth remembering for the next headless test, since it cost real debugging time here (same family of issue as the `get_tree().current_scene` quirk documented back in Milestone 5).

Verified with a headless scripted test against the real `Playground` scene (old dressing gone, 6 houses/mailboxes present, 19+ meters of unobstructed riding, then a full ride-to-mailbox-and-throw scoring exactly 10), and with the real exported Web build: both a genuine keyboard session and a genuine synthetic-touch session rode through the neighborhood and delivered successfully (Score: 10), zero console errors, with screenshots confirming the road/sidewalk/houses/trees/streetlights/mailbox all read clearly from the follow camera.

### Next Session

- Consider a second neighborhood block or a turn in the road, now that the street kit is reusable.
- Revisit the on-screen directional cue toward the active mailbox now that mailboxes are spread across 6 houses instead of 3 open-field targets.

---

## Day 8

### Completed

- Merged Milestone 7 (First Neighborhood) to `main`, confirmed CI + Pages deploy green, then built Milestone 8 ("Game Feel") on its own branch. No new mechanics — every change is tuning, feedback, or polish on the existing ride/throw/deliver loop, with every tunable value exported rather than hard-coded (including a couple of pre-existing hard-coded literals — `SquashStretch`'s jump feedback, `HUD`'s celebration tween — cleaned up along the way).
- Bike feel: smoothed steering input, a small cosmetic cornering speed loss, a brake-dive pitch, and a continuous speed-scaled suspension bounce plus landing compression — all cheap per-frame math on `LeanPivot`, no tweens or allocations. Every landing now gives a little suspension "give"; a hard landing additionally still triggers the existing squash-stretch plus a new one-shot dust puff and thump sound.
- Camera feel: subtle anticipation (leads slightly in the direction of travel), dynamic speed-based zoom, a very subtle turn tilt (derived from the target's own yaw rate, not from reaching into Player internals), and a brief landing impulse driven directly off `Player.landed` — the camera rig stays decoupled from Player's specific exports.
- Throw feel: a brief windup between pressing throw and the newspaper actually launching (with an immediate anticipation squash and a whoosh synced to the real launch), a gentle apex-synced scale pulse on the newspaper's arc, a quick impact pop instead of an instant vanish, and mailboxes now visibly wobble on delivery.
- Audio: three new procedurally-synthesized placeholder sounds (throw whoosh, landing thump, a seamlessly-looping ride hum whose volume/pitch track speed), plus a small random pitch variance on the existing delivery chime so repeated deliveries don't sound identical. Same synthesis-at-build-time technique as the original chime — no external assets.

### Notes

One real bug in the new wiring script, caught immediately by re-inspecting the saved scene rather than by a runtime crash: duplicating the existing `DustEmitter` node to create the new one-shot `LandingDust` used `duplicate(Node.DUPLICATE_USE_INSTANTIATION)` — passing that flag *alone* excludes Godot's default `DUPLICATE_SCRIPTS` flag, so the duplicate silently lost its script entirely. `player.gd` was already defensively checking `landing_dust.has_method("burst")` before calling it, so this would have failed silent (no dust, no error) rather than crashing — worth remembering that defensive `has_method()` guards can mask a real wiring mistake just as easily as they prevent a crash. Fixed by adding the script reference back explicitly.

Draw calls were sampled at several points in the real Web build and ranged from 46 to 459 depending on camera facing — much wider than Milestone 7's single reported "135". Investigated to rule out a regression (compared node counts, checked screenshots for duplicated geometry) before concluding it's architectural: the neighborhood is one long, perfectly straight, unobstructed street (a Milestone 7 layout choice, already logged as a known limitation), so depending on which way the camera happens to be facing, it can see anywhere from one nearby house to the entire 60m corridor at once. This milestone added exactly one new draw call (the one-shot landing dust); everything else added was audio (zero rendering cost) or pure script logic. Worth revisiting if the street is ever extended significantly — a turn in the road, or simple distance-based culling/fog, would cap the worst case.

Verified with a headless scripted test against the real `Playground` scene (acceleration, a nonzero suspension offset, lean reacting to cornering, brake-dive pitch, and a full ride-throw-deliver cycle — now including the windup — scoring correctly), and with the real exported Web build: both a genuine keyboard session and a genuine synthetic-touch session delivered successfully (Score: 10), zero console errors.

### Next Session

- A turn or second block in the street, both to break up the long sightline (draw calls, visual variety) and to give the modular kit its first real reuse test.
- Revisit the on-screen directional cue toward the active mailbox — still open from Milestone 7.

---

# Current Version

v0.1.0-alpha (released) — Milestone 7 (First Neighborhood) merged to `main`. Milestone 8 (Game Feel) is complete on its own branch, awaiting review before merging.

---

# Known Issues

- No Android export templates or Android SDK installed in the current dev environment, so the Android export preset is untested end-to-end (project-side configuration only). Android is not yet part of the CI/CD pipeline.
- Running the project under `--headless` (no GPU/display) logs a benign `mesh_get_surface_count` "Parameter m is null" error per `MeshInstance3D` — this is a known artifact of Godot's dummy rendering driver used for headless validation and does not occur with a real display/GPU or in the exported Web build (confirmed clean in an actual browser).
- WASM multithreading is disabled in the Web export preset because GitHub Pages cannot serve the `Cross-Origin-Opener-Policy` / `Cross-Origin-Embedder-Policy` headers it requires. Not a problem today; would need Cloudflare Pages (or similar) if threading becomes necessary later.
- The camera has no dedicated look input by design (mobile controls are movement + jump only) — it auto-orients behind the player's facing direction. This matches the intended mobile-first UX but means there's currently no way to look around independently of moving.
- Concurrent multitouch (dragging the joystick while tapping jump/throw) relies on Godot's native browser touch handling, which is well-established engine behavior; it was exercised sequentially in automated testing rather than via a hand-crafted concurrent synthetic touch sequence, since accurately simulating true concurrent multitouch through raw DOM events is significantly more complex than the engine behavior it would be verifying.
- No on-screen indicator for *which direction* the active mailbox is when it's off-screen — the player currently has to explore/remember the map. The gold target ring is only visible once the mailbox is in view.
- All audio (delivery chime, throw whoosh, landing thump, ride hum) is procedurally-generated placeholder tone/noise, not mixed/mastered audio.
- The BMX has no collision-based crash/fail state — riding into a house, tree, streetlight, or any other scenery just stops the bike against the obstacle rather than producing dedicated feedback (a bump animation, a sound, etc.).
- The BMX's placeholder frame/wheel geometry is intentionally simple (primitive meshes matching the existing low-poly placeholder character) and not final bike art.
- Draw calls swing widely (46-459 observed) depending on camera facing, since the neighborhood is one long unobstructed straight street — see Day 8 notes. Not a performance problem today, but worth addressing (a turn in the road, or distance culling/fog) if the street grows.
- The neighborhood is a single straight street (no turns, intersections, or a second block yet) — the modular road/sidewalk/curb kit supports extending it, but no branching layout exists yet.
- "Front lawn" is the existing grass ground plane reused everywhere road/sidewalk/driveway pieces don't cover, not a distinct piece of geometry — a deliberate simplification (this is a level-design milestone, not an art one), noted here in case future art wants dedicated lawn texturing/edging.
- All 6 houses reuse the same placeholder art (only scale and facing vary) — no visual house variants yet.

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
