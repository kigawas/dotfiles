# dotfiles

Personal configuration for [pi](https://pi.dev), [Claude Code](https://github.com/anthropics/claude-code), and Antigravity (`agy`) — plus global Git config and helper scripts.

## Install

```bash
./install.sh                   # dry run: print planned links, change nothing
./install.sh --apply           # create links for all scopes
./install.sh --apply claude pi # create links for specific scopes
./install.sh --help            # full list of links
```

`install.sh` is idempotent: links that already point to this repo are left alone, and any existing file or folder it would replace is moved to `~/.dotfiles-backup/<timestamp>/` first.

### Scopes

Passing no scope runs all four:

| Scope | Target | What gets linked |
| --- | --- | --- |
| `claude` | `~/.claude/` | `CLAUDE.md` (`agents/AGENTS.md`), `commands/`, `agents/*`, and the subset of `skills/` listed in `CLAUDE_SKILLS` |
| `pi` | `~/.pi/agent/` | `AGENTS.md`, `prompts/` (`commands/`), `mcp.json`, `extensions/*`, `agents/*` |
| `gemini` | `~/.gemini/` | `skills/*/` and `antigravity-cli/statusline.sh` (read by `agy`) |
| `misc` | `~/.agents/skills/`, `~/.config/git/` | All `skills/*/`, `git/config`, `git/ignore` |

### Not linked

- `claude/settings.json`, `pi/settings.json`, `gemini/settings.json`, and `agents/skill-lock.json` are tracked as manual copies and kept in sync by hand.
- The root `AGENTS.md` and `CLAUDE.md` are instructions for working on this repo and are not installed.

## What's here

### Shared agent setup

- `agents/AGENTS.md` — Shared user instructions linked to Claude Code and pi.
- `agents/skill-lock.json` — Copy of `~/.agents/.skill-lock.json` (`npx skills` lockfile).
- `commands/` — Slash commands shared by both tools: `/commit`, `/fold`, `/ship`, `/merged`, `/clear-comments`.
- `skills/` — Twelve skills, grouped by use:
  - **Git & PR workflow**: `open-branch`, `pr`, `clear-branch`
  - **Review & scheduled loops**: `adversarial-review`, `author-loop`, `review-loop`
  - **Design, testing & writing**: `codebase-design`, `domain-modeling`, `improve-codebase-architecture`, `writing-tests`, `grilling`, `writing-for-agents`

### Tool-specific config

- `claude/agents/`, `pi/agents/` — The `adversarial-reviewer` subagent, one file per tool.
- `claude/settings.json`, `pi/settings.json`, `gemini/settings.json` — Settings copies for Claude Code, pi, and `agy`.
- `gemini/statusline.sh` — Status line script for `agy` (shows model, mode, context usage, and cache hit rate).
- `pi/extensions/` — `zsh-bang` runs `!` and `!!` commands in zsh with `~/.zshrc`; `idle-compact` compacts a session after 55 minutes idle, before the 1-hour prompt cache expires.
- `pi/mcp.json` — pi MCP servers (`@playwright/mcp`).

pi's `loop`, `secret-guard`, and `command-guard` extensions live in a separate package, [`@gridport/pi-extensions`](https://github.com/gridport/pi-extensions), pinned in `pi/settings.json`.

### Git & scripts

- `git/config` — Global git settings (`~/.config/git/config`): the `lg` log alias and SSH `allowedSignersFile`.
- `git/ignore` — Global gitignore (`~/.config/git/ignore`): `.DS_Store`, Claude Code local settings, `*.log`, and `*.env`.
- `scripts/git-sign.sh` — Configures SSH commit signing in the current repo.
- `scripts/check-pi-models.sh` — Checks or fixes `supportsMidConvoEffort` in `~/.pi/agent/models.json` after a provider catalog update.
- `scripts/mobile-setup.sh` — Sets up an Android cloud environment: links these dotfiles and installs the Android SDK and Kotlin.

## Before you borrow

- Provider, model, and hook settings are personal: pi reaches its models through [magpie](https://github.com/yetone/magpie). Swap in your own provider and settings.
- `~/.pi/agent/models.json` holds API keys and is never committed here.

## License

MIT; see [LICENSE](LICENSE). Seven of the skills come from [mattpocock/skills](https://github.com/mattpocock/skills), also MIT (`skills/pr` also adapts HumanLayer's `show-me` skill); see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
