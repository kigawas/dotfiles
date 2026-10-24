# Dotfiles repo instructions

This repo holds Ryan's personal config: shared agent instructions, skills, pi settings, and the install and helper scripts.

## Layout

- `agents/AGENTS.md`: shared user instructions. `install.sh` links it to `~/.claude/CLAUDE.md` and `~/.pi/agent/AGENTS.md`. Keep it tool-neutral. Ask before changing it.
- `skills/<name>/`: skills, each linked into `~/.agents/skills/` one at a time.
- `pi/settings.json`: a copy of `~/.pi/agent/settings.json`. Nothing links it. When you change one, change the other and compare them.
- `.pi/settings.json`: project settings for this repo only.
- `scripts/`: helper scripts.

## Rules

- Never copy `~/.pi/agent/models.json` into this repo. It holds API keys.
- Run `./install.sh` as a dry run. Ask before running `./install.sh --apply`.
- Stage with explicit paths: `git add -- <path>`. Never use `git add -A`.
- Commit messages use `[Tag]: summary`, such as `[Pi]`, `[Agents]`, or `[Scripts]`.
- Don't push unless asked.
- Pin third-party pi packages to exact versions, and review their source before installing.
