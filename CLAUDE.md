# shown-setup

Public one-command bootstrap installer that gets a new Shown Media teammate's Mac ready for Claude Code. This repo is just `install.sh` + `README.md` — no app, no build, no tests, no runtime deps.

## What + where
- Purpose: `curl -fsSL https://raw.githubusercontent.com/shownmedia/shown-setup/main/install.sh | bash` — installs Homebrew/gh/node/Claude Code, signs into GitHub, adds Shown's private plugin marketplace, hands off to Claude for the rest.
- GitHub remote: `shownmedia/shown-setup` (public). Branch `main`.
- Deploy: none — this is a static script served raw from GitHub. There's no build/CI; a push to `main` is live immediately (the curl URL points at `main`).
- Hosting: no server, no Railway/Vercel. Pure shell script.

## Code map
- `install.sh` — the entire installer, in 7 numbered steps (read top-to-bottom, it's linear):
  1. Xcode CLI tools check
  2. Homebrew install
  3. `gh` + `node` via brew
  4. Claude Code native installer (`claude.ai/install.sh`)
  5. `gh auth login` + org-membership check against `shownmedia` org/`shown-claude` repo
  6. Adds marketplace `https://github.com/shownmedia/shown-claude.git` (name `shown`), installs plugins `shown-core` + `keep-awake-charging`, then runs shown-core's `settings.sh` (`.../plugins/shown-core/skills/shown-setup/scripts/settings.sh`)
  7. `exec claude "Run Shown setup for me."` — hands off to the `shown-setup` skill (lives in the *other* repo, `shown-claude`) for logins/Google/Slack/Figma/etc. Uses a plain-English prompt, not `/shown-setup`, because installed plugin skills are namespaced (`shown-core:shown-setup`) and a bare slash command does not resolve (fixed in commit 008df1f — do not revert to a slash command).
- `README.md` — the one-liner teammates paste, plus the org-invite prerequisite.
- To change what gets installed or which plugins ship by default: edit step 6 in `install.sh` directly, no other file.
- To change what happens *after* handoff (logins, settings, skills): that's in `shownmedia/shown-claude`, NOT here. See Related repos.

## Data
None. No DB, no state file, no secrets stored in this repo. The only "state" it touches on the user's machine is standard tool installs (`~/.zprofile`, `~/.zshrc` PATH lines) and Claude's own plugin marketplace config (`~/.claude/plugins/marketplaces/`). Also writes `~/.claude/settings.json` (bypass-permissions on, via shown-core's `settings.sh`) and git credential config (via `gh auth setup-git`).

## Commands
- Run it: `bash install.sh` (or via the curl one-liner in README.md). Idempotent — re-running skips anything already installed (`has()` checks, marketplace/plugin list checks). Exception: on a brand-new Mac with no Xcode CLI tools, the first run exits 0 after triggering the Xcode install popup and prints instructions to re-run; that is expected, not a failure — it's a two-pass flow on first use.
- No install/build/test/lint — there's no package.json, no CI config in this repo.
- No dry-run mode. To check a change without side effects, use `bash -n install.sh` (syntax check) or read the diff; running it for real triggers live installs, `settings.json` edits, and execs into Claude at the end.

## Env vars
None read or set by this script itself. Downstream (post-handoff) env/secrets setup happens in `shown-claude`'s `shown-setup` skill, not here.

## Gotchas
- Verified against memory `project_shown_claude_setup.md`: Shown's actual skills (shown-core, shown-launch, shown-dev, etc.) do NOT live in this repo or in `~/.claude/skills` — they live in the private marketplace repo `shownmedia/shown-claude` (local clone `~/shown-claude`). This repo only bootstraps the marketplace connection.
- `install.sh` requires macOS (`uname == Darwin`); on other OS it prints manual marketplace-add instructions and exits 1.
- `exec </dev/tty` at the top is deliberate — needed because the script is piped from curl, so prompts (sudo password, `gh auth login`) still reach the real keyboard.
- The org-membership check (step 5) gates everything after it: no `shownmedia` org access -> script exits 1 with instructions to ask Mitchell or Alejandro for an invite.
- Plugin source must be an `https://` git URL, not SSH — noted in memory as a past failure mode for the marketplace add (relevant if this script's marketplace URL is ever changed).

## Related repos
- `shownmedia/shown-claude` (local `~/shown-claude`) — the actual private plugin marketplace this installer connects to. Contains plugins `shown-core`, `shown-launch`, `shown-dev`, plus URL-source plugins `keep-awake-charging` and `beat-cut-edit`. All real skill edits happen there, not in `shown-setup`. See its own CLAUDE.md / memory `project_shown_claude_setup.md` for details.
