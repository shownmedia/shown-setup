# Shown setup

One command to get a Shown Media teammate's Mac ready for Claude Code. Open Terminal and paste:

```
curl -fsSL https://raw.githubusercontent.com/shownmedia/shown-setup/main/install.sh | bash
```

It installs Claude Code and the basics, signs you into GitHub, adds Shown's skills, then opens Claude to walk you through the rest. Safe to run again any time.

This one is for people who build Shown's bots and apps: it needs the `shownmedia` GitHub org. Everyone else installs Claude Code and their AI bot with the public command, no GitHub needed:

```
curl -fsSL https://raw.githubusercontent.com/shownmedia/ai-me/main/setup.sh | bash
```
