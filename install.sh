#!/bin/bash
# Shown Media: one-command Claude Code setup for a new teammate's Mac.
#
#   curl -fsSL https://raw.githubusercontent.com/shownmedia/shown-setup/main/install.sh | bash
#
# Installs Homebrew, git, GitHub CLI and Claude Code, signs you into GitHub (browser),
# adds Shown's private plugin marketplace, then opens Claude and runs /shown-setup,
# which handles everything else. Safe to run again; it skips what's already done.
set -euo pipefail

bold() { printf '\n\033[1m%s\033[0m\n' "$*"; }
has() { command -v "$1" >/dev/null 2>&1; }

if [ "$(uname)" != "Darwin" ]; then
  echo "This installer is for Macs. On another OS, install Claude Code (https://claude.com/claude-code),"
  echo "then run: claude plugin marketplace add https://github.com/shownmedia/shown-claude.git"
  echo "          claude plugin install shown-core@shown   and type /shown-setup in Claude."
  exit 1
fi

# curl | bash leaves stdin as the script; prompts need the keyboard.
exec </dev/tty

bold "Shown setup: this takes about 5 minutes. You'll type your Mac password once or twice."

# 1. Xcode command line tools (git, compilers)
if ! xcode-select -p >/dev/null 2>&1; then
  bold "Installing Apple's developer tools. A popup will open: click Install, wait for it, then run this command again."
  xcode-select --install >/dev/null 2>&1 || true
  exit 0
fi

# 2. Homebrew
if ! has brew; then
  bold "Installing Homebrew (asks for your Mac password)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"
if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
  echo "eval \"\$($(command -v brew) shellenv)\"" >> "$HOME/.zprofile"
fi

# 3. Core tools
bold "Installing GitHub CLI and Node"
for f in gh node; do has "$f" || brew install "$f"; done

# 4. Claude Code (native installer, auto-updates itself)
if ! has claude; then
  bold "Installing Claude Code"
  curl -fsSL https://claude.ai/install.sh | bash
fi
export PATH="$HOME/.local/bin:$PATH"
grep -q '.local/bin' "$HOME/.zshrc" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"

# 5. GitHub sign-in (Shown's skills live in a private repo)
if ! gh auth status >/dev/null 2>&1; then
  bold "Sign in to GitHub. A browser window opens; use the account that's in the shownmedia org."
  gh auth login --web --git-protocol https --hostname github.com
fi
gh auth setup-git
if ! gh api orgs/shownmedia/repos -q '.[0].name' >/dev/null 2>&1 || ! gh api repos/shownmedia/shown-claude >/dev/null 2>&1; then
  bold "Your GitHub account can't see Shown's repos yet."
  echo "Ask Mitchell or Alejandro to add $(gh api user -q .login 2>/dev/null || echo you) to the shownmedia GitHub org,"
  echo "accept the email invite, then run this same command again."
  exit 1
fi

# 6. Shown plugin marketplace + core plugins
bold "Adding Shown's skills to Claude Code"
claude plugin marketplace list 2>/dev/null | grep -q 'shown' \
  || claude plugin marketplace add https://github.com/shownmedia/shown-claude.git
claude plugin marketplace update shown >/dev/null 2>&1 || true
for p in shown-core keep-awake-charging; do
  claude plugin list 2>/dev/null | grep -q "$p@shown" || claude plugin install "$p@shown"
done
bash "$HOME/.claude/plugins/marketplaces/shown/plugins/shown-core/skills/shown-setup/scripts/settings.sh" || true

# 7. Hand off to Claude for logins and the rest
bold "Almost done. Claude opens next."
echo "If it asks you to log in to Claude, use your Shown account. Then it runs /shown-setup and"
echo "walks you through Google, Slack, Figma and the rest."
sleep 2
exec claude "/shown-setup"
