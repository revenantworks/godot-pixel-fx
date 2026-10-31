# Changelog

All notable changes to Pixel FX Starter. Versions follow semantic versioning.

## [Unreleased]

Nothing yet.

## [0.1.0] - 2026-10-31

First public release.

### Added

- Five `canvas_item` shaders in `addons/pixel_fx/shaders/`: `outline`, `hit_flash`,
  `palette_swap`, `dissolve` and `pixelate`. Each reads whole texels with `texelFetch`, so
  no shader blends half pixels, whatever filter the node uses.
- Demo scene `demo/demo.tscn`: each shader on one sprite, a slider or toggle per setting,
  an animate mode, and keys (Space, P, A).
- Tests: 30 tests in 3 files. 9 run headless; 21 render on a GPU and check exact pixels.
- Tools: `make_palette.gd` builds a palette texture from a sprite;
  `capture_screenshots.gd` takes store screenshots from the real demo scene;
  `check.sh` and `check.ps1` run every check.
- Apache-2.0 `LICENSE` and a `NOTICE` file, at the root and inside `addons/pixel_fx/`.
- Demo sprite: the wizard from Tiny Dungeon by Kenney (CC0), credited in `demo/art/CREDITS.md`.
- Repository: security policy, support, code of conduct, contributing and accessibility
  guides, issue and pull request templates, CODEOWNERS and Dependabot for Actions.
- CI on every push to `main`: the full test suite on Godot 4.7.2 (hash-checked download),
  a PII scan of every file and commit identity, and CodeQL on the workflows.
- Three screenshots of the real demo scene in `screenshots/`.
- A PII pre-commit hook (`.githooks/`), armed with `git config core.hooksPath .githooks`.
