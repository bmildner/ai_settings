# Claude Code

Shared Claude Code configuration, kept under version control so it can be reused
across machines and installations.

## Contents

- `statusline.sh` — custom statusline script (pure bash + `jq`, no Node/Bun
  dependency).
- `settings.json` — global settings (`model`, `effortLevel`, `theme`,
  `statusLine` command, etc.).
- `keybindings.json` — custom keybindings (empty `{}` until customized).
- `CLAUDE.md` — global instructions loaded in every session, across all
  projects.
- `agents/` — custom agent definitions.
- `skills/` — custom skills.

## Setup instructions

Target locations are under `~/.claude/`. For every item **except
`settings.json`**, link it — don't copy — so the live file in `~/.claude` and
the file in this repo are the same file:

```bash
REPO=/path/to/this/repo/claude_code
CLAUDE=~/.claude

ln -sf "$REPO/statusline.sh"            "$CLAUDE/statusline.sh"
ln -sf "$REPO/keybindings.json"         "$CLAUDE/keybindings.json"
ln -sf "$REPO/CLAUDE.md"                "$CLAUDE/CLAUDE.md"
ln -sf "$REPO/agents"                   "$CLAUDE/agents"
ln -sf "$REPO/skills"                   "$CLAUDE/skills"
```

`settings.json` is the one exception: **copy it, don't symlink it.**

```bash
cp "$REPO/settings.json" "$CLAUDE/settings.json"
```

Reason: Claude Code reads *and writes* `settings.json` during normal use
(e.g. `/model`, `/theme` persist their changes there). Symlinking it would
mean every routine session mutates the tracked repo file directly. Keeping it
a plain copy lets you update the repo's version deliberately and re-copy it
when you want to pull in changes, instead of the repo picking up incidental
local state automatically.

If a target file already exists as a real file (not a symlink), back it up
before replacing it, e.g.:

```bash
mkdir -p "$CLAUDE/backups/pre-symlink-$(date +%Y%m%d%H%M%S)"
cp -a "$CLAUDE/<file>" "$CLAUDE/backups/pre-symlink-$(date +%Y%m%d%H%M%S)/"
```

## Notes for an AI assistant operating on this repo

- Do not symlink `settings.json` — always copy it, per above.
- Everything else in this directory (current and future files/dirs) should be
  symlinked from `~/.claude`, not copied, so edits in either location stay in
  sync.
- JSON files must never be left as empty (zero-byte) files — an empty file is
  invalid JSON. Use `{}` as the minimal placeholder.
- Before overwriting or deleting a real (non-symlink) file under `~/.claude`,
  back it up first (see above).
