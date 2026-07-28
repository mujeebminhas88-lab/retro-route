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

## Day 9

### Completed

- Merged Milestone 8 (Game Feel) to `main`, confirmed CI + Pages deploy green, then built Milestone 9 ("The First Route") on its own branch: turns the sandbox into the game's first complete playable session — spawn, a "START ROUTE" prompt, a 3-2-1-GO! countdown, a fixed 5-mailbox route delivered in a taught order, ROUTE COMPLETE, a results screen, and Play Again.
- Replaced `DeliveryManager` with `RouteManager` (`game/scripts/gameplay/route_manager.gd`, same file renamed rather than layered alongside — the delivery-order logic fundamentally changes from group-shuffle to a fixed ordered list, and the new responsibilities are strictly a superset of the old ones). Its delivery order is exported scene data (`Array[NodePath]`), not hard-coded, so the same script is reusable for any future neighborhood.
- Route design: `Mailbox1 -> Mailbox4 -> Mailbox3 -> Mailbox5 -> Mailbox2` (skipping `Mailbox0`), picked by computing real distances in the Milestone 7 neighborhood so difficulty ramps close -> a bit farther -> a turn back the way the player came -> the route's longest ride (~40m) -> a short, satisfying final hop.
- Newspaper bundle: exactly 5 newspapers for the 5-stop route (previously infinite). A miss refunds the newspaper via the existing hit/miss signal path rather than costing the run — one mechanic satisfying both "limited supply" and "misses shouldn't be punishing."
- New `SaveData` helper (`game/scripts/systems/save_data.gd`) persists a local best score via `ConfigFile` to `user://` (IndexedDB-backed in the Web export, survives reloads).
- New flow UI: `RouteIntroUI` (START ROUTE button -> animated countdown) and `ResultsScreen` (score/deliveries/accuracy/time/best score + Play Again), both purely reactive to `RouteManager` signals, matching the existing HUD's relay-only pattern.
- Completion polish stayed deliberately subtle and reused existing mechanisms: `FollowCamera.celebrate()` is the same decaying landing-impulse code from Milestone 8 with the sign flipped (a small rise instead of a dip), and a new short four-note fanfare (same build-time PCM synthesis as the rest of the audio kit) plus a one-shot gold particle burst play once on completion.

### Notes

The brief's literal flow diagram listed the countdown *before* "Press START ROUTE." Read literally that has no coherent UX reading (a countdown can't precede its own trigger), so the flow was reordered to idle-with-a-prompt -> countdown -> active, which is what actually ships. Flagging this here as a deliberate interpretation rather than a silent deviation.

Two real bugs, both caught by testing rather than code review:

1. The first headless wiring run (renaming `DeliveryManager` to `RouteManager`, re-pointing its script, wiring the new UI) executed *before* Godot's global class cache had ever seen the newly-created `route_manager.gd`/`save_data.gd` files, so every script referencing `RouteManager`/`SaveData` as a static type (`hud.gd`, `thrower.gd`, `results_screen.gd`, `route_manager.gd` itself) failed to parse mid-run. The save still completed, silently dropping several exported properties along the way (Thrower's `route_manager_path` never got set; some Player/CameraRig tunables got serialized as explicit defaults they used to omit). Godot's headless mode doesn't rebuild the class cache on its own the way opening the editor does — the fix was a `godot4 --headless --editor --quit-after 1` pass (forces a project scan that regenerates `global_script_class_cache.cfg`) before re-running the wiring script cleanly. Since the real M9 changes had already been committed by that point, discarding and redoing the broken save was a plain `git checkout --`.
2. `RouteIntroUI`'s countdown label was only hidden via a `modulate.a` fade set in code, never an explicit `visible = false` — so before the route's first `state_changed` signal ever fires (i.e., the entire `IDLE` state, including the very first frame), the label sat at its scene-default `visible = true`, invisible only by chance (zero alpha) rather than by design. Caught by an explicit headless assertion ("Countdown hidden while IDLE"), not by eye. Fixed by setting `visible = false` in `_ready()` alongside the alpha reset.

Verified with a headless scripted test driving the real `Playground` scene end-to-end: `RouteManager` starts `IDLE`, `start_route()` enters `COUNTDOWN`, transitions to `ACTIVE` with the bundle sized to exactly 5, a deliberate off-target throw refunds its newspaper without counting as a delivery, all 5 deliveries complete in the expected order, score lands on exactly 50, the results screen shows the correct score/deliveries/accuracy (83% — the test's one deliberate miss plus 5 hits), best score persists via `SaveData`, and `restart_route()` correctly re-enters `COUNTDOWN` — 26/26 assertions passed.

In the real exported Web build, both a genuine keyboard session and a genuine touch session completed the full route end-to-end: a real mouse click (move+down+hold+up — a bare `page.mouse.click()` didn't reliably register against the Godot Web canvas, worth remembering for future Playwright tests against this project) started the route, real `F` keypresses (keyboard session) or real taps on the THROW button (touch session) threw each newspaper, and both reached Score: 50, 5/5 deliveries, the ROUTE COMPLETE screen with a correct "New Best!" best-score flourish, and a working Play Again back into `COUNTDOWN` — zero console errors either way. Both sessions used the temporary debug bridge's teleport escape hatch to skip only the BMX pathing between mailboxes; steering the bike competently isn't what this browser test is verifying (the headless test above already exhaustively covers the route logic, including a full completion with genuine physics-driven throws), and a crude scripted pursuit bot fighting a deliberately long ~40m traversal added test flakiness without adding coverage.

### Next Session

- The on-screen directional cue toward the active mailbox is still open (Milestone 7/8 carryover) — now more noticeable on the route's longest leg (Mailbox3 -> Mailbox5, ~40m).
- Consider whether a second fixed route (reusing `RouteManager` as designed) is worth building before any progression/unlock system, once that's back in scope.

---

## Day 11

### Completed

Milestone 10.1 ("Mobile Stability & Delivery Reliability") — a stabilization pass in response to a real-device playtest report that Milestone 10 "runs glitchy," with mailboxes appearing too close together, rapid swipes failing to register, and throws sometimes producing no delivery. No new gameplay this session; the brief was explicit that automated tests passing doesn't mean the game feels reliable, and to audit the actual implementation rather than assume a cause. Full root-cause list, fixes, and testing are in CHANGELOG.md; this entry covers the investigation process and what didn't make the cut.

### Notes

Started with a static read-through of the whole delivery/streaming/input pipeline (`road_streamer.gd`, `route_manager.gd`, `thrower.gd`, `swipe_throw_gesture.gd`, `touch_button.gd`, `hud.gd`, `mailbox.gd`) rather than jumping to a fix. That read alone surfaced most of the real bugs before any testing: the route-start skip-flicker and the near-zero first-reaction-time mailbox both fall directly out of the interaction between `blocks_behind` (pre-spawned for visual continuity) and mailbox registration happening on every block; the silent-miss gap was confirmed with a single grep (`delivery_missed` had no listeners anywhere); the swipe multitouch drop and the skip-margin-vs-in-flight-hit race were both found by tracing what happens when two things overlap in time that the original code implicitly assumed wouldn't.

Performance was the one area where static reading wasn't enough to be confident, so it got measured rather than guessed at twice. First attempt: a browser-side `requestAnimationFrame` recorder over a ~95s ride. Useless as a *diagnostic* — the sandbox's software-WebGL fallback (`--use-gl=swiftshader`, confirmed via a console warning) was so slow on its own (mean ~545ms/frame) that it swamped any smaller structural signal from block spawning. Second attempt: moved the measurement inside the engine (`_process(delta)` + `get_tree().get_node_count()` logged every frame, read back from JS via `JavaScriptBridge.eval`), which at least confirmed the streamed set stays bounded (node count flattens at ~603-606 after the initial fill and never climbs further over the rest of a long run) but still found no statistically distinct spike correlated with spawn events — the software-rendering floor was still too dominant relative to whatever a spawn actually costs. Third attempt, and the one that actually answered the question: dropped the browser entirely and timed `NeighborhoodBlock.tscn.instantiate()` directly in native headless Godot, isolated from all rendering. Mean 0.70ms, p95 0.83ms, max 3.9ms per instantiate — cheap next to any real frame budget, even generously discounting for WASM being several times slower than native. Concluded block-spawn instantiation is not a supported root cause and did not implement the block-pooling optimization that had been the leading hypothesis going in; the brief's instruction against unjustified changes applies to performance work exactly as much as it does to a new cooldown or a new feature.

All fixes were verified two ways. First, a new temporary headless test script (16 assertions: no start-flicker, mailbox spacing, the in-flight-hit-vs-skip race surviving a simulated skip, overlapping-touch multitouch tracked and resolved independently, and a full 20-delivery run driven end-to-end through the real streaming pipeline with bounded block count) driving the actual `Playground` scene and calling into the real production methods (`_handle_pointer`, `_on_delivered`, `_check_skip_passed_mailbox`, `_recycle_and_stream`) rather than isolated unit logic — this is the strongest evidence for this milestone, since it exercises the exact code path a real gesture or a real race would hit. Second, the real Web export exercised with Playwright: a keyboard session confirmed the new hit/miss HUD feedback renders correctly live (a screenshot mid-run shows "Missed!" in the HUD, something that used to be completely silent) with zero console errors, riding and throwing all behaving correctly through the real input pipeline.

The CDP overlapping-touch test (one swipe held open while a second, different-direction swipe starts and completes before the first releases -- the exact scenario the multitouch fix targets) did not land cleanly in the real Web export this session. Two attempts: the first dispatched the touch sequence after the score/delivery HUD had already been active and accumulating for ~25s (so timing wasn't the issue), and produced no error but also no registered throw (score/deliveries unchanged before and after). Isolating further with a single-finger-only CDP swipe (removing the multitouch variable entirely) to check whether the CDP dispatch pipeline itself was reaching the game at all in that run hit a *different* problem: this sandbox's countdown/boot timing varied enough between otherwise-identical runs (still showing the countdown digit "1" a full 7 seconds after the START ROUTE click, versus under 4 seconds in earlier runs the same session) that the diagnostic swipe likely landed before controls were even enabled, not after. Given real time constraints, didn't chase this further -- it matches the CDP-automation timing variance already logged in this file from Milestone 10 (see Known Issues), not a new discovery. The multitouch fix's correctness rests on the headless simulation above, which is a legitimate verification of the actual code path; what's still open is a live-browser (ideally real-device, not CDP-synthesized) confirmation of the *feel* of two overlapping real touches.

The newspaper-into-mailbox docking animation the brief raised (Phase 6) was deliberately scoped down rather than skipped silently: the `DeliveryPoint` marker was moved from just outside the mailbox's collision box to inside it (a one-line transform change, low risk), but a real "flap opens, newspaper settles in" animation would touch Newspaper's flight/impact code more substantially than felt appropriate to combine with a stability-focused pass — flagged as a good scope for its own short milestone once this one is confirmed solid on a real phone.

### Next Session

- Get this build in front of an actual phone, not just headless-Chromium/CDP automation — every fix here was verified as thoroughly as this environment allows, but real touch hardware, real GPU rendering, and real network conditions are the only way to confirm the original "glitchy" report is actually resolved rather than just its known causes being fixed.
- If real-device testing still shows periodic stutter after this pass, revisit the `thread_support=false` Web export setting and the block-pooling idea shelved this session — the instantiate-cost measurement ruled it out as a *root cause* here, but a genuinely underpowered phone is a different environment than this sandbox's cloud CPU.
- The newspaper docking/flap-open animation (Phase 6 of the M10.1 brief) is still open — scoped down to a marker-position fix this session, see CHANGELOG.md.

---

## Day 10

### Completed

- Merged Milestone 9 (The First Route) to `main`, confirmed CI + Pages deploy green, then built Milestone 10 ("Mobile Arcade Controls & Streamed Route") on its own branch: a control-and-route foundation redesign responding to real problems that only showed up once the route stopped being a short, hand-authored 5-stop loop — the heading-based BMX could swerve unpredictably, auto-targeted throwing didn't read as deliberate, and a fixed route visibly ends.
- Bike handling: replaced heading-based steering with a constant world forward axis plus a smoothed lateral strafe (`player.gd`, full rewrite). The bike physically cannot rotate its heading anymore — steering is a sideways velocity, not a turn — which incidentally makes throw-direction reversal structurally impossible rather than merely guarded against, since the rider's left/right and world -X/+X are now the same thing by construction.
- Mobile controls: removed the virtual joystick; added three large hold buttons (LEFT/BRAKE/RIGHT, bottom row) plus a full-screen swipe layer for directional throwing (`touch_controls.gd`, `swipe_throw_gesture.gd`). Keyboard gets Q/E for throw-left/throw-right alongside the existing A/D steer and S brake.
- Streamed route: a new `RoadStreamer` spawns/recycles a repeating `NeighborhoodBlock` around the player (bounded active set, always 6 in practice) and `RouteManager` was substantially reworked to take mailboxes as they're dynamically registered rather than from a fixed list, completing at a delivery count (20) instead of "reached the end."
- Kept the single ground plane as one big static (4000x4000) plane rather than streaming it — collision floor doesn't need to move with the player the way visible dressing does, and one huge static plane is essentially free.

### Notes

The brief specified an exact three-button bottom layout (LEFT bottom-left, BRAKE bottom-center, RIGHT bottom-right) with no room reserved for anything else, and separately specified throwing move to a full-screen swipe gesture instead of a button. Read together this meant the on-screen JUMP/THROW buttons from Milestones 5-9 had no place left in the new layout — jump doesn't appear anywhere in the brief's five-action control list either ("steer left, steer right, brake, throw left, throw right"). Interpreted this as jump being cut from the *mobile* control surface for this milestone (the keyboard binding and Player's underlying jump physics are untouched, just not reachable from a touch button) rather than removing jump outright, since ripping out a working, unrelated system wasn't asked for and the brief only speaks to the five listed actions. Flagging this as a deliberate, narrow interpretation rather than a silent scope change.

Three real bugs, all caught by testing rather than code review:

1. The new bottom-center BRAKE button sits in the exact same screen region as the pre-existing START ROUTE button (also bottom-center, unchanged from Milestone 9) and the PLAY AGAIN button. `TouchButton` uses a raw `_input()` override that marks events handled as soon as a press lands in its rect — since it's processed before Godot's own internal Control/GUI click routing reaches the real `Button` node underneath, BRAKE was silently eating every click meant for START ROUTE, and the route could never actually be started from a touch/mouse interaction. Caught immediately once real Web testing was attempted (a genuine click sat on "IDLE" forever with zero console errors — nothing throws, it just silently does nothing). Fixed by gating all of TouchControls (LEFT/BRAKE/RIGHT and the swipe layer) to only be enabled while `RouteManager.state == ACTIVE`, which is also just correct UX — there's nothing to steer/brake/throw before the ride begins, and it means the road-streaming-on-COUNTDOWN change (below) and this fix reinforce each other.
2. Rapid-fire throwing at the same still-active mailbox (two newspapers in flight at once, both captured as "hit" against the same target at throw time) could double-credit a single mailbox once both landed — the second, stale `delivered` signal was crediting the score/delivery count a second time for a mailbox `RouteManager` had already advanced past. Caught while stress-testing the swipe gesture with an intentionally aggressive spam-throw bot. Fixed with a one-line guard in `_on_delivered()`: a delivery signal for a mailbox that's no longer the tracked active one is treated as a miss (refunded) instead of double-counted.
3. `SwipeThrowGesture`'s duration check (differencing two `Time.get_ticks_msec()` reads at press and release) read as wildly inflated — multiple real seconds — specifically for touch/mouse events synthesized via CDP's `Input.dispatchTouchEvent` in headless Chromium automation, even though the exact same gesture's distance/direction math computed correctly and `_physics_process`-driven systems (bike movement, brake easing) tracked real elapsed time normally throughout the very same test session. Root cause not fully pinned down (likely some rAF-adjacent scheduling quirk specific to CDP-driven synthetic input, since real touch hardware drives the browser's normal continuous rendering loop and wouldn't hit this path at all) but conclusively isolated to timestamp differencing specifically: rewrote the duration measurement to accumulate via `_process(delta)` while a pointer is held, tying it to the same per-frame clock the rest of gameplay already trusts, rather than two independent `Time.get_ticks_msec()` samples. This is a strictly more robust implementation regardless of the CDP quirk, not just a workaround for it.

Verified with a headless scripted test driving the real `Playground` scene end-to-end: zero horizontal velocity while `IDLE`/`COUNTDOWN` even with steer held, `RoadStreamer` already populated by the time `COUNTDOWN` starts, auto-forward begins exactly at `ACTIVE`, LEFT/RIGHT steer laterally and recenter on release, BRAKE slows and recovers correctly, a full 20-delivery run completes with an exact 10/10 left/right split (score 200), `restart_route()` re-enters `COUNTDOWN` with the block count still bounded (6) — 23/23 assertions passed, plus a separate quick regression pass after the swipe-duration rewrite (20/20 deliveries, score 200) to confirm it didn't disturb anything.

In the real exported Web build: a genuine keyboard session (real click on START ROUTE using the M9-established move+down+hold+up pattern, real A/D/S/Q/E keypresses) completed the full 20-delivery route end-to-end — Score: 200, ROUTE COMPLETE, "New Best!", working Play Again back into `COUNTDOWN` — with zero console errors, riding nearly 500m through the streamed neighborhood with the active block count staying bounded the entire time (confirming the streaming system holds up well beyond a short test run). A genuine touch session confirmed LEFT/RIGHT/BROKE (via CDP `Input.dispatchTouchEvent`, since Playwright's own `touchscreen` API only supports instant taps, not held presses or drags) all produce the correct effect matching the keyboard session, with a screenshot confirming the three-button layout renders exactly as specified (bottom row, clear separation, BRAKE visibly highlighted mid-press). The swipe gesture's own distance/direction/delivery pipeline was independently confirmed correct (temporarily disabling the duration gate produced a clean single-newspaper consumption exactly matching the swiped direction), but a full touch-only 20-delivery completion could not be achieved inside this specific CDP-driven automation harness due to the duration-timing quirk described above — not expected to affect real touch devices, whose input isn't synthesized through CDP at all.

### Next Session

- The on-screen directional cue toward the active mailbox (open since Milestone 7) matters more now that mailboxes appear continuously along an unbounded ride rather than at 3-5 known fixed spots.
- Revisit whether a real touch device (not just headless CDP automation) confirms the swipe gesture feels good in practice — the underlying logic is verified correct, but real-device swipe *feel* (distance/duration defaults) hasn't been hand-tested on hardware.
- The boost hook (`Player.boost_speed_multiplier`/`is_boosting`) is wired but inert — a future milestone can drive it from a checkpoint/objective without touching movement code again.

---

## Day 12

### Completed

Milestone 10.2 ("Core Ride & Delivery Reset") — a second, larger correction after a real-phone playtest of the 10.1 preview still found the game glitchy: swipe throwing unreliable and unpleasant, mailboxes still too dense, the bike itself bumpy/glitchy, and the newspaper not convincingly landing in the mailbox. This time swipe throwing is gone entirely, not just made more reliable — replaced with a simple contextual tap. Full root-cause list and fixes are in CHANGELOG.md; this entry covers the investigation and a couple of test-methodology traps worth remembering.

### Notes

The swipe-vs-tap decision was made by the brief, not discovered here — worth noting because it changes the shape of the fix from "make the gesture detector more robust" (10.1's approach) to "delete the gesture detector." `SwipeThrowGesture` is gone; the replacement (`ThrowArrowButton`) is deliberately close to the existing `TouchButton` in structure (same `_input()`-claims-the-event-first pattern, same `Rect2` hit-test) specifically so it inherits the same, already-proven-in-production input-ordering guarantees rather than reinventing them.

The bumpy-bike investigation is the interesting one. The brief was explicit not to assume it was suspension and to look for evidence, so the read started from `player.gd`'s suspension code (a small, slow sine bounce — plausible but weak as a sole explanation for "glitchy") and worked outward. `follow_camera.gd`'s `SpringArm3D` does its own collision-avoidance shape-cast every physics frame, and a project-wide grep for `collision_layer`/`collision_mask` came back completely empty — every `StaticBody3D` in the project, decorative or not, was sitting on Godot's default layer/mask (1/1). Cross-referencing prop X-positions against `Player.lateral_bounds` (±6.2) found the actual overlap: Mailbox sits at x=±5.9, Tree at ±6.3, Streetlight at ±3.75 — all inside the player's own reachable strip, and Mailbox in particular is present (both sides) on nearly every block. Wrote a two-line headless repro rather than trust the arithmetic alone: instantiate a `Player` and a `Mailbox` at the mailbox's real in-game position, call `move_and_slide()`, read `get_slide_collision_count()`. It came back 1, against the mailbox, confirmed layer 1 on both sides. That's a real, frequent physical collision the player's own bike was catching on as it rode past roadside dressing — not a metaphorical "feels bumpy," an actual `CharacterBody3D` contact event, on essentially every mailbox and a fair number of trees/streetlights too. Fixed by moving House/Streetlight/Tree/Mailbox to `collision_layer = 2, collision_mask = 0`; re-ran the identical repro afterward and got 0. Left the suspension bounce alone — it was never shown to be a meaningful contributor, and changing it too would have muddied which fix actually mattered.

Two things worth remembering for future headless tests in this project, both hit while writing this milestone's test suite:

1. GDScript lambdas capture outer local variables **by value**, not by reference — `func(): some_local_bool = true` mutates the lambda's own copy, and the enclosing scope never sees it. A test asserting a signal fired via a captured `bool` silently always failed even though the signal (confirmed via an added `print` inside the lambda) was firing correctly. Fixed by capturing a single-element `Array` instead (arrays are reference types, so mutating index 0 from inside the lambda is visible outside it) — the standard GDScript idiom for this, now worth remembering rather than re-discovering.
2. A `Control` node instantiated inside a headless `SceneTree` test (no real viewport layout/render pass) can have `size == Vector2.ZERO` even after being added to the tree, since anchors/offsets never get resolved without an actual layout pass. A `Rect2(global_position, size).has_point(...)` hit-test against such a node will always fail, silently, with no error — looks exactly like "the tap isn't registering" when it's actually "the rect has no area." Fixed by explicitly setting `.size` on the control before hit-testing it directly in a test; not an issue in the real game, where `TouchControls` lives inside a real, laid-out `CanvasLayer`.

Verified with a headless test driving the real `Playground` scene (16/16 assertions): the three prop collision-layer fixes confirmed directly, the swipe file confirmed deleted, both throw arrows confirmed present and correctly hidden before the route starts, the new spacing constant, `get_valid_throw_side()`'s pre-route "none" result, the debounce lock genuinely blocking then releasing a tap, and a full 20-delivery run accelerated via `Engine.time_scale = 14` (driven through real keyboard-action input, not a position teleport, so the actual streaming/registration/window-check pipeline is exercised throughout) reaching `route_completed` with `delivery_succeeded` firing exactly 20 times and the streamed block count staying bounded (max 6) the whole way. Two real Web export sessions followed: the first (~13s of active riding, well short of the first 96m delivery point — this sandbox's software rendering runs noticeably slower than real-time, so a fixed real-time budget covers less game-distance than in earlier milestones' shorter-spacing tests) confirmed zero console errors and smooth, visually stable riding with correct LEFT/BRAKE/RIGHT rendering; the second, longer session actually reached and tapped a live throw arrow, with the HUD afterward reading **Score: 10, Deliveries: 1/20, Newspapers: 519** — a real, live-browser delivery through the entire new tap pipeline, not just a headless assertion.

### Next Session

- This sandbox's software rendering makes it impractical to watch a full real-browser 20-delivery run end-to-end in one Playwright session at a reasonable time cost; the accelerated headless run is the practical source of truth for full-route behavior, with short real-browser sessions used to confirm the live input/render pipeline itself. A real phone doesn't have this constraint and is still the real test.
- The mail slot/flap is a fixed-geometry cue, not a per-throw docking simulation — good enough per the brief's own allowance for a controlled arcade trajectory, but worth revisiting if a future milestone wants a more elaborate delivery moment.
- Worth a broader sweep of `collision_layer`/`collision_mask` across any *future* new scenery props — the pattern that caused this milestone's core bug (new prop, no explicit layer, silently shares layer 1 with Player/Ground/camera) is easy to reintroduce by habit.

---

# Current Version

v0.1.0-alpha (released) — Milestone 9 (The First Route) merged to `main`. Milestone 10 (Mobile Arcade Controls & Streamed Route) is merged to `main` and deployed. Milestone 10.1 (Mobile Stability & Delivery Reliability) and Milestone 10.2 (Core Ride & Delivery Reset) are both complete on their own branches, awaiting player review after live-preview phone testing before either merges — Milestone 10 was found to have real-device reliability issues after deployment (see Day 11), and the 10.1 preview was itself found still glitchy on a real phone, prompting 10.2 (see Day 12).

---

# Known Issues

- No Android export templates or Android SDK installed in the current dev environment, so the Android export preset is untested end-to-end (project-side configuration only). Android is not yet part of the CI/CD pipeline.
- Running the project under `--headless` (no GPU/display) logs a benign `mesh_get_surface_count` "Parameter m is null" error per `MeshInstance3D` — this is a known artifact of Godot's dummy rendering driver used for headless validation and does not occur with a real display/GPU or in the exported Web build (confirmed clean in an actual browser).
- WASM multithreading is disabled in the Web export preset because GitHub Pages cannot serve the `Cross-Origin-Opener-Policy` / `Cross-Origin-Embedder-Policy` headers it requires. Not a problem today; would need Cloudflare Pages (or similar) if threading becomes necessary later.
- The camera has no dedicated look input by design (mobile controls are steer/brake/throw only) — it auto-orients behind the player's facing direction. This matches the intended mobile-first UX but means there's currently no way to look around independently of moving.
- No on-screen indicator for *which direction* the active mailbox is when it's off-screen — the player currently has to notice it appear as the road streams in. The gold target ring is only visible once the mailbox is in view. More noticeable now that mailboxes appear continuously rather than at a few known fixed spots.
- All audio (delivery chime, throw whoosh, landing thump, ride hum, completion fanfare) is procedurally-generated placeholder tone/noise, not mixed/mastered audio.
- (Updated, Milestone 10.2) The BMX has no collision-based crash/fail state by design (out of scope per every milestone brief so far) — and as of 10.2, it no longer physically collides with roadside scenery at all. House/Streetlight/Tree/Mailbox were moved off the player's collision layer specifically because that collision was an unintended bug (the actual cause of the "bumpy" complaint, see Day 12), not because scenery collision was ever a desired gameplay feature; the bike now rides through/past decorative props cleanly.
- The BMX's placeholder frame/wheel geometry is intentionally simple (primitive meshes matching the existing low-poly placeholder character) and not final bike art. The bike also no longer visually leans into a "turn" the way it did in Milestones 6-8, since Milestone 10 replaced heading-based steering with a lateral strafe — the small cosmetic lean/roll is still there, driven by lateral speed, but there's no yaw rotation left to lean *into*.
- The streamed neighborhood is a single straight corridor (no turns, intersections, or side streets) — `RoadStreamer`/`NeighborhoodBlock` support extending the block template, but no branching layout exists yet. Since only a bounded number of blocks (6) are ever active regardless of how far the player has ridden, draw calls should be far more stable across a long run than Milestone 7-8's fully-static neighborhood was, but this hasn't been freshly re-measured after the Milestone 10 rework.
- Every streamed block reuses the same house/driveway/bush/mailbox/streetlight/tree placement (only left/right mirroring varies) — no visual variety block-to-block yet, and the milestone brief explicitly deferred prop/house/mailbox variation to a future milestone.
- Only one side of each block's two placed mailboxes is ever a real deliverable target (the other sits permanently inert/gray) — this exactly matches how 5 of 6 mailboxes already looked throughout Milestones 7-9, so it's not a visual regression, but it does mean roughly half of the visible mailboxes in any given view are never deliverable.
- No pause/quit-mid-route option — once "START ROUTE" is pressed the only way back to `IDLE` is finishing the route (or reloading the page).
- The mobile control surface (LEFT/BRAKE/RIGHT + throw arrows) is disabled outside the `ACTIVE` state by design (see Day 10 notes) — this is required to avoid the BRAKE/START-ROUTE click conflict, but also means a player can't "practice" the controls before the countdown finishes.
- `page.mouse.click()` doesn't reliably register against this project's Godot Web canvas in headless Chromium/Playwright testing; an explicit move + mousedown + short hold + mouseup does (established in Milestone 9, still true).
- (Resolved, Milestone 10.2) CDP-synthesized touch/mouse events could produce wildly inflated `Time.get_ticks_msec()` duration readings when sampled inside custom input-event handlers, which repeatedly blocked fully-automated touch-only testing in Milestones 10 and 10.1 (see their Day 10/11 notes) and was never conclusively resolved as a testing-harness issue. Milestone 10.2 removed the dependency entirely rather than continuing to work around it: swipe throwing (the only place duration was measured) is gone, replaced with an instant tap that has no duration to measure. No longer a relevant limitation for this project.
- (Milestone 10.1, superseded by 10.2) Widening mailbox spacing to fix reaction-time pacing meant a full 20-delivery route covered roughly 2x the distance/time it did at Milestone 10's launch. Milestone 10.2 widened it again, roughly another 2x (see below) — if comparing session-length notes across milestones, check which spacing was in effect.
- (Milestone 10.2) Mailbox spacing is now ~96m / ~14.8s between delivery opportunities (`mailbox_spacing_blocks = 4`, up from 10.1's 2/48m) — a full 20-delivery route now covers roughly 1920m+ / ~5 minutes at cruise speed, a substantially longer and slower-paced session than any earlier milestone. Intended per the 10.2 brief's explicit "not a tiny numerical adjustment" instruction, but worth knowing when comparing session lengths or planning future playtest time.
- (Milestone 10.2) The newspaper-into-mailbox visual was upgraded (a real slot + hinged flap reaction on delivery, see Day 12/CHANGELOG) but is still a fixed-geometry cue driven by a deterministic arcade trajectory, not a per-throw physically simulated docking animation — an intentional scope choice per the brief's own allowance, not an oversight.
- All fixes in Milestones 10.1 and 10.2 were verified via headless scripted tests and Web-export Playwright automation, per this environment's established testing capability — none of it is a substitute for hands-on testing on a real phone, which is what reported Milestone 10's original "glitchy" issue and then found the 10.1 preview still glitchy in turn. Real-device confirmation of the 10.2 preview is still outstanding — see the live preview URL provided alongside this milestone's report.

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
