# Changelog

All notable changes to Retro Route will be documented in this file.

## [Unreleased]

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
