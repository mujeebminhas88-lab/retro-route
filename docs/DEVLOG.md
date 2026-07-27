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

- [ ] Player movement
- [ ] Camera system
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

# Current Version

v0.0.2 (Pre-Production — Project Foundation)

---

# Known Issues

- No Android export templates or Android SDK installed in the current dev environment, so the Android export preset is untested end-to-end (project-side configuration only).
- Running the project under `--headless` (no GPU/display) logs a benign `mesh_get_surface_count` "Parameter m is null" error per `MeshInstance3D` — this is a known artifact of Godot's dummy rendering driver used for headless validation and does not occur with a real display/GPU.

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
