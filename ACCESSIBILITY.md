# Accessibility

## Our commitment

We want everyone to be able to read, install, and use these shaders. That includes people who
use screen readers, a keyboard only, or high zoom.

## Supported environments

- Documentation: Markdown, read on GitHub or in any text editor.
- Shaders and demo: Godot 4.7 or later.
- Check scripts: Bash on Linux or macOS, PowerShell 7 on Windows.

## What we do

- We write documentation in plain language, with short sentences.
- We keep headings in order and give links descriptive text.
- The demo scene works with the mouse and has keys for its main actions (Space, P, A).
- We fix reported barriers as quickly as we can.

## Known limits

- We have not had a formal accessibility audit.
- The demo scene's sliders and toggles have not been tested with a screen reader.
- `hit_flash` and the demo's animate mode flash the screen. Turn animate off with **A**.
- Some documents use tables and code blocks that a screen reader may read slowly.

## Report a barrier

Open an issue and choose "Accessibility barrier":
<https://github.com/revenantworks/godot-pixel-fx/issues/new/choose>.
Tell us where you hit the barrier and what you use. If you would rather not use a public
issue, use the private form in `SECURITY.md`.
