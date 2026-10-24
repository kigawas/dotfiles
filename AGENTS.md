# Dotfiles repo instructions

This repo holds Ryan's personal config: shared agent instructions, skills, pi settings, and the install and helper scripts.

## Layout

- `agents/AGENTS.md`: shared user instructions. `install.sh` links it to `~/.claude/CLAUDE.md` and `~/.pi/agent/AGENTS.md`. Keep it tool-neutral. Ask before changing it.
- `agents/skill-lock.json`: a copy of `~/.agents/.skill-lock.json`, the `npx skills` record of installed skills and their sources. Nothing links it. Copy it again after installing or updating skills.
- `skills/<name>/`: skills, each linked into `~/.agents/skills/` one at a time.
- `claude/settings.json`: a copy of `~/.claude/settings.json`. Nothing links it. When you change one, change the other and compare them.
- `claude/agents/`, `pi/agents/`: user-level subagents, each file linked into `~/.claude/agents/` or `~/.pi/agent/agents/`. One agent has a file in each, since the two tools name tools and models differently. Keep both thin: point at a skill's file for the substance.
- General skills replace copies kept in several repos. Repository details stay in the repository: commands and policy in its `AGENTS.md`, review stakes and traps in `docs/review-notes.md`.
- Same-name precedence differs by tool. A repository's own agent overrides the user-level one in both. For skills, pi prefers the repository's copy, but Claude Code prefers the personal one in `~/.claude/skills/`. So link a general skill into `~/.claude/skills/` only after the repositories' own copies are removed.
- `commands/`: slash commands shared by both tools. `install.sh` links the folder to `~/.claude/commands` and `~/.pi/agent/prompts`. Use only frontmatter and placeholders both read: `description`, `argument-hint`, `$ARGUMENTS`.
- `pi/settings.json`: a copy of `~/.pi/agent/settings.json`. Nothing links it. When you change one, change the other and compare them. Its `skills` entries such as `-skills/wizard/SKILL.md` turn off skills from `~/.agents/skills/`, matching `skillOverrides` in `claude/settings.json`.
- `pi/mcp.json`: user-level MCP servers, linked to `~/.pi/agent/mcp.json`. Pin each server's package version.
- `pi/extensions/`: pi extensions, each file linked into `~/.pi/agent/extensions/`. Their tests are in `pi/extensions/tests/`, which `install.sh` doesn't link. After changing an extension, run `pi/extensions/tests/run.sh --mutants`, and also `run.sh --live` (about 5 minutes, a few cents) when the change touches how it talks to pi.
- `.pi/settings.json`: project settings for this repo only.
- `scripts/`: helper scripts.

## Rules

- Never copy `~/.pi/agent/models.json` into this repo. It holds API keys.
- Run `./install.sh` as a dry run. Ask before running `./install.sh --apply`.
- Stage with explicit paths: `git add -- <path>`. Never use `git add -A`.
- Commit messages use `[Tag]: summary`, such as `[Pi]`, `[Agents]`, or `[Scripts]`.
- Don't push unless asked.
- Pin third-party pi packages to exact versions, and review their source before installing.
