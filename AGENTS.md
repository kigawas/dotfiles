# Dotfiles repo instructions

This repo holds Ryan's personal config: shared agent instructions, skills, pi settings, and the install and helper scripts. It's public on GitHub.

## Layout

- `agents/AGENTS.md`: shared user instructions. `install.sh` links it to `~/.claude/CLAUDE.md` and `~/.pi/agent/AGENTS.md`. Keep it tool-neutral. Ask before changing it.
- `agents/skill-lock.json`: a copy of `~/.agents/.skill-lock.json`, the `npx skills` record of installed skills and their sources. Nothing links it. Copy it again after installing or updating skills.
- `skills/<name>/`: skills, each linked into `~/.agents/skills/` one at a time.
- `claude/settings.json`: a copy of `~/.claude/settings.json`, minus its `autoMode` block, which names private repos and stays in the live file only. Nothing links it. When you change one, change the other, then compare them with `diff <(jq -S 'del(.autoMode)' ~/.claude/settings.json) <(jq -S . claude/settings.json)`.
- `claude/agents/`, `pi/agents/`: user-level subagents, each file linked into `~/.claude/agents/` or `~/.pi/agent/agents/`. One agent has a file in each, since the two tools name tools and models differently. Keep both thin: point at a skill's file for the substance.
- General skills replace copies kept in several repos. Repository details stay in the repository: commands and policy in its `AGENTS.md`, review stakes and traps in `docs/review-notes.md`.
- Same-name precedence differs by tool. A repository's own agent overrides the user-level one in both. For skills, pi prefers the repository's copy, but Claude Code prefers the personal one in `~/.claude/skills/`. So link a general skill into `~/.claude/skills/` only after the repositories' own copies are removed.
- `commands/`: slash commands shared by both tools. `install.sh` links the folder to `~/.claude/commands` and `~/.pi/agent/prompts`. Use only frontmatter and placeholders both read: `description`, `argument-hint`, `$ARGUMENTS`.
- `pi/settings.json`: a copy of `~/.pi/agent/settings.json`. Nothing links it. When you change one, change the other and compare them. Its `skills` entries such as `-skills/wizard/SKILL.md` turn off skills from `~/.agents/skills/`, matching `skillOverrides` in `claude/settings.json`.
- `pi/mcp.json`: user-level MCP servers, linked to `~/.pi/agent/mcp.json`. Pin each server's package version.
- `pi/extensions/`: pi extensions, each file linked into `~/.pi/agent/extensions/`.
- `loop`, `secret-guard` and `command-guard` come from the npm package `@gridport/pi-extensions`, pinned in `pi/settings.json`'s `packages`. Change them in its repo, `~/works/js/pi-extensions`. After it releases, move the pin in both settings files.
- `git/config`: global git settings, linked to `~/.config/git/config`, which git reads before `~/.gitconfig`. Settings that belong to one machine, such as user and credential helpers, stay in `~/.gitconfig`.
- `.pi/settings.json`: project settings for this repo only.
- `scripts/`: helper scripts.

## Rules

- Never copy `~/.pi/agent/models.json` into this repo. It holds API keys.
- Everything committed here is public. Before committing, check that the diff names no private repo, work project or private folder.
- Run `./install.sh` as a dry run. Ask before running `./install.sh --apply`.
- Stage with explicit paths: `git add -- <path>`. Never use `git add -A`.
- Commit messages use `[Tag]: summary`, such as `[Pi]`, `[Agents]`, or `[Scripts]`.
- Don't push unless asked.
- Pin third-party pi packages to exact versions, and review their source before installing.
