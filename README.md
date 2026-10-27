# dotfiles

My setup for two coding agents, [pi](https://pi.dev) and [Claude Code](https://github.com/anthropics/claude-code): shared instructions, skills, slash commands, subagents, pi extensions, settings, and the script that installs them.

## Install

```bash
./install.sh              # dry run: prints what it would link, changes nothing
./install.sh --apply      # makes the links
./install.sh --apply pi   # only the links into ~/.pi/agent
```

The scopes are `claude` (links into `~/.claude`), `pi` (into `~/.pi/agent`) and `misc` (the shared skills and the git config). Without one, `install.sh` runs all three.

`install.sh` links files from this repo into `~/.claude`, `~/.pi/agent`, `~/.agents/skills` and `~/.config/git`. It leaves a link that already points here alone, and moves a file it would replace to `~/.dotfiles-backup/<timestamp>/` first. Run `./install.sh --help` for the full list of links.

The settings files aren't linked. `claude/settings.json` and `pi/settings.json` are copies, kept in step with `~/.claude/settings.json` and `~/.pi/agent/settings.json` by hand.

## What's here

| Path | What |
| --- | --- |
| `agents/AGENTS.md` | Instructions both agents read, linked as `~/.claude/CLAUDE.md` and `~/.pi/agent/AGENTS.md`. |
| `skills/` | Skills: adversarial review, opening and clearing branches, working your own queue or reviewing others' PRs on a recurring trigger, TDD, codebase design, domain modeling, grilling a plan, and writing for agents. |
| `commands/` | Slash commands both agents read: `/commit`, `/ship`, `/merged`, `/fold`, `/clear-comments`. |
| `claude/agents/`, `pi/agents/` | An adversarial-reviewer subagent, one file per tool. |
| `pi/extensions/` | `zsh-bang` runs your own `!` commands in zsh with `~/.zshrc`; `idle-compact` compacts a session before its cache expires. |
| `pi/mcp.json` | pi's MCP servers. |
| `claude/settings.json`, `pi/settings.json` | The settings copies. |
| `git/config` | Global git settings, linked as `~/.config/git/config`: the `lg` alias and the allowed-signers file for SSH signatures. |
| `agents/skill-lock.json` | The `npx skills` record of installed skills and their sources. |
| `scripts/` | `git-sign.sh` sets up SSH commit signing in a repo; `check-pi-models.sh` checks pi's `models.json` after a provider update. |

pi's `loop`, `secret-guard` and `command-guard` extensions are a separate package, [`@gridport/pi-extensions`](https://github.com/gridport/pi-extensions), pinned in `pi/settings.json`.

The root `AGENTS.md` is for agents working on this repo; it isn't installed.

## Before you borrow

- The model and provider settings are mine: pi reaches its models through [magpie](https://github.com/yetone/magpie). Use your own provider.
- pi's `models.json` holds API keys, so it's never copied here.

## License

MIT; see [LICENSE](LICENSE). Six of the skills come from [mattpocock/skills](https://github.com/mattpocock/skills), also MIT; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
