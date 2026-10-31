# Contributing

Thanks for helping. This repo ships to the public, so one rule comes before everything else:
**no personal data reaches a commit.** No name, no personal or machine path, no machine or
account name, no email address, no secret.

## Set up a clone (once)

```bash
git clone https://github.com/revenantworks/godot-pixel-fx.git
cd godot-pixel-fx
git config core.hooksPath .githooks      # arms the PII pre-commit hook
GODOT=/path/to/godot tools/check.sh      # Windows: pwsh -File tools/check.ps1 -Godot <Godot console exe>
```

`core.hooksPath` is stored in the clone's own config. A fresh clone does not have it: run the
`git config` line in each new clone.

Commit with your GitHub no-reply address (Settings, Emails, "Keep my email addresses private"):

```bash
git config user.email "<id>+<login>@users.noreply.github.com"
```

The hook blocks a commit whose author or committer email is not a no-reply address.

## The PII barrier

- **Pre-commit hook** (`.githooks/pre-commit`): runs `python tools/pii_scan.py --staged` on the
  added lines of the staged diff and blocks the commit on any hit. It fails closed: with no
  Python 3.9+ it blocks too.
- **Your own global guard, if you have one:** `core.hooksPath` makes git skip a machine-wide
  hooks folder, so `.githooks/pre-commit` and `.githooks/pre-push` also call the `pii_guard.py`
  found in your global `core.hooksPath`. Without one, nothing extra runs.
- **CI** (`.github/workflows/pii-scan.yml`): runs `python tools/pii_scan.py --tree --identities`
  over every tracked file and every commit identity on each push to `main`.

The scanner is vendored from revenantworks/claude-skills (`tools/pii_scan.py` and
`tools/pii/`). A hit prints `path:line  rule  fp=<fingerprint>`, never the value. Fix the line
and stage again. **Never use `--no-verify`.** A file that must hold a fake path or key is
accepted by rule and by one file in `.pii-scan.json`; use example values (`example.com`,
`~/path/to/file`).

## Tests

Every change runs `tools/check.sh` in CI (`.github/workflows/ci.yml`): import, 9 headless tests,
then 21 render tests checked pixel by pixel on a software GPU. Run it before you push.

- A new test goes in `tests/test_*.gd` and raises `EXPECTED_TESTS` in `tests/run_tests.gd`.
  A new test file also raises `EXPECTED_SCRIPTS`. The runner fails on a count that differs, so
  a file that fails to parse cannot hide.
- A render test never counts as passed under `--headless`. It is skipped there.
- Never weaken a check to make it pass. Fix the shader or the test's expectation, and say why.

## Shaders

- Read texture pixels with `texelFetch`, never `texture()`, so nothing blends half pixels.
- Carry the node's modulate through the `modulate` varying, as the existing shaders do.
- Keep every uniform in the README table for its shader, with its default.

## Art

Demo art must be CC0 or your own work. Credit it in `demo/art/CREDITS.md`. No AI-made images,
sounds or fonts.

## Commits

`<scope>: <imperative summary>` on the first line, then a body that says why. Scopes:
`shaders`, `demo`, `tools`, `tests`, `docs`, `ci`.
