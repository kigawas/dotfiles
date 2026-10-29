#!/usr/bin/env bash
# Link the files in this repo to the places the tools read them from.
#
# Usage:
#   ./install.sh [scope...]           dry run: print what would change, change nothing
#   ./install.sh --apply [scope...]   make the changes
#
# A scope is named for where its links land: all (the default), claude, pi
# or misc. Name several to run several, such as ./install.sh --apply claude pi.
#
#   claude: links into ~/.claude
#     agents/AGENTS.md     -> ~/.claude/CLAUDE.md
#     commands/            -> ~/.claude/commands
#     claude/agents/<file> -> ~/.claude/agents/<file>         (one link per file)
#     ~/.agents/skills/<name> -> ~/.claude/skills/<name>      (only CLAUDE_SKILLS;
#                             relative, as npx skills links them for Claude Code)
#   pi: links into ~/.pi/agent
#     agents/AGENTS.md     -> ~/.pi/agent/AGENTS.md
#     commands/            -> ~/.pi/agent/prompts
#     pi/mcp.json          -> ~/.pi/agent/mcp.json
#     pi/extensions/<file> -> ~/.pi/agent/extensions/<file>   (one link per file)
#     pi/agents/<file>     -> ~/.pi/agent/agents/<file>       (one link per file)
#   misc: everything else
#     skills/<name>/       -> ~/.agents/skills/<name>   (one link per skill; both
#                             tools read them, and other skills there are left alone)
#     git/config           -> ~/.config/git/config
#     git/ignore           -> ~/.config/git/ignore
#
# Idempotent: a link that already points at the repo is left alone.
# A file or folder that gets replaced is moved to ~/.dotfiles-backup/<timestamp>/
# before the link is created.

set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd -P)"
# Skills Claude Code also reads as personal ones. It prefers a personal skill to
# a repo's own copy of the same name, so see AGENTS.md before adding one here.
CLAUDE_SKILLS=(writing-tests)
BACKUP_ROOT="${HOME}/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
APPLY=0
BACKED_UP=0
SCOPES=""

for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    all|claude|pi|misc) SCOPES="$SCOPES $arg" ;;
    # The comment block at the top, up to the first line that isn't a comment.
    -h|--help) awk 'NR > 1 && !/^#/ { exit } NR > 1' "$0"; exit 0 ;;
    *) echo "unknown argument: $arg (scopes: all, claude, pi, misc; see --help)" >&2; exit 2 ;;
  esac
done
SCOPES="${SCOPES# }"
SCOPES="${SCOPES:-all}"

# in_scope NAME: whether this run includes scope NAME, and if so, print its heading.
in_scope() {
  case " $SCOPES " in
    *" all "* | *" $1 "*) echo; echo "[$1]" ;;
    *) return 1 ;;
  esac
}

# link SOURCE TARGET
link() {
  local src="$1" dst="$2"

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "ok       $dst"
    return 0
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    echo "replace  $dst -> $src (old version backed up)"
  else
    echo "link     $dst -> $src"
  fi

  [ "$APPLY" = 1 ] || return 0

  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    local rel="${dst#"$HOME"/}"
    mkdir -p "$BACKUP_ROOT/$(dirname "$rel")"
    mv "$dst" "$BACKUP_ROOT/$rel"
    BACKED_UP=1
  fi
  ln -s "$src" "$dst"
}

echo "repo: $REPO"
[ "$APPLY" = 1 ] && echo "mode: apply" || echo "mode: dry run (pass --apply to make changes)"
echo "scope: $SCOPES"

if in_scope claude; then
  link "$REPO/agents/AGENTS.md" "$HOME/.claude/CLAUDE.md"
  link "$REPO/commands" "$HOME/.claude/commands"
  for agent in "$REPO"/claude/agents/*.md; do
    [ -f "$agent" ] || continue
    link "$agent" "$HOME/.claude/agents/$(basename "$agent")"
  done
  for skill in "${CLAUDE_SKILLS[@]}"; do
    link "../../.agents/skills/$skill" "$HOME/.claude/skills/$skill"
  done
fi

if in_scope pi; then
  link "$REPO/agents/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
  link "$REPO/commands" "$HOME/.pi/agent/prompts"
  link "$REPO/pi/mcp.json" "$HOME/.pi/agent/mcp.json"
  for ext in "$REPO"/pi/extensions/*.ts; do
    [ -f "$ext" ] || continue
    link "$ext" "$HOME/.pi/agent/extensions/$(basename "$ext")"
  done
  for agent in "$REPO"/pi/agents/*.md; do
    [ -f "$agent" ] || continue
    link "$agent" "$HOME/.pi/agent/agents/$(basename "$agent")"
  done
fi

if in_scope misc; then
  for skill_dir in "$REPO"/skills/*/; do
    [ -d "$skill_dir" ] || continue
    link "${skill_dir%/}" "$HOME/.agents/skills/$(basename "$skill_dir")"
  done
  link "$REPO/git/config" "$HOME/.config/git/config"
  link "$REPO/git/ignore" "$HOME/.config/git/ignore"
fi

if [ "$BACKED_UP" = 1 ]; then
  echo
  echo "backups: $BACKUP_ROOT"
fi
