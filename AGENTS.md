# Dotfiles repo instructions

Personal dotfiles for Claude Code, pi, Antigravity (`agy`), and Git. This repository is **public on GitHub**.

Run `./install.sh --help` for the exact symlink map. Always run `./install.sh` as a dry run first, and ask before running `./install.sh --apply`.

## Synced copies (not symlinked)

`install.sh` leaves these files alone; keep each repo copy and live file in sync by hand:

- `claude/settings.json` ↔ `~/.claude/settings.json`, **excluding `autoMode`** (which names private repos and stays in the live file only). After editing either file, verify with:
  `diff <(jq -S 'del(.autoMode)' ~/.claude/settings.json) <(jq -S . claude/settings.json)`
- `pi/settings.json` ↔ `~/.pi/agent/settings.json`. Compare both after editing. Disabling a skill in `~/.agents/skills/` uses `-skills/<name>/SKILL.md` in `pi/settings.json` and `skillOverrides` in `claude/settings.json` — keep both aligned.
- `gemini/settings.json` ↔ `~/.gemini/antigravity-cli/settings.json`, **keeping only `colorScheme` and `statusLine`** (other live settings stay in the live file only).
- `agents/skill-lock.json` ← `~/.agents/.skill-lock.json`. Re-copy after installing or updating skills with `npx skills`. Keep every skill stored in `skills/` **out** of the lock, even an unchanged upstream copy (otherwise `npx skills update` deletes its symlink and overwrites it with upstream). Remove entries by editing the lock directly, since `npx skills remove` also deletes symlinks.

## Authoring conventions

- **Shared instructions (`agents/AGENTS.md`)**: Keep tool-neutral. Ask before changing it.
- **Skills (`skills/<name>/`)**: General skills replace per-repo copies. Keep repository-specific details in each repo (`AGENTS.md` for commands and policy; `docs/review-notes.md` for review stakes, traps, and running rules).
- **Skill and agent precedence**: A repo's own subagent overrides the user-level copy in both tools. For skills, pi prefers the repo copy, while Claude Code prefers `~/.claude/skills/`. Add a skill to `CLAUDE_SKILLS` in `install.sh` only after repos' own same-name copies are removed (`writing-tests` is an intentional exception while some repos still keep `tdd`, so Claude Code loads both there).
- **Subagents (`claude/agents/`, `pi/agents/`)**: Maintain one file per tool since tool and model names differ. Keep both thin and point to a skill file for the substance.
- **Commands (`commands/`)**: Shared by Claude Code and pi. Use only frontmatter and placeholders both support: `description`, `argument-hint`, `$ARGUMENTS`.
- **Pi packages and MCP (`pi/settings.json`, `pi/mcp.json`)**: Pin third-party pi packages and MCP servers to exact versions, and review their source before installing.
- **`@gridport/pi-extensions`**: `loop`, `secret-guard`, and `command-guard` live in the separate `gridport/pi-extensions` repo. Edit them there; after a release, bump the version pin in both `pi/settings.json` and `~/.pi/agent/settings.json`.
- **Git (`git/config`, `git/ignore`)**: Keep machine-specific settings (user identity, credential helpers) in `~/.gitconfig`, and language or build ignores in each repo's `.gitignore`.

## Security and Git workflow

- **Public repo check**: Keep `~/.pi/agent/models.json` out of this repo (never copy it here — it holds API keys). Before committing, check the diff to confirm it names no private repo, work project, or local/private folder.
- **Staging**: Stage explicit paths with `git add -- <path>` (never `git add -A`).
- **Commits**: Use `[Tag]: summary`, such as `[Pi]`, `[Agents]`, `[Skills]`, or `[Scripts]`.
- **Pushing**: Do not push unless asked.
- **GitHub CLI**: The remote is `kigawas/dotfiles`. Run `gh` as `kigawas` without switching accounts: `GH_TOKEN=$(gh auth token --user kigawas) gh ...`.
