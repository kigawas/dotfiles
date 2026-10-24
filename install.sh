#!/usr/bin/env bash
# Link the files in this repo to the places the tools read them from.
#
# Usage:
#   ./install.sh           dry run: print what would change, change nothing
#   ./install.sh --apply   make the changes
#
# Links:
#   agents/AGENTS.md     -> ~/.claude/CLAUDE.md
#   agents/AGENTS.md     -> ~/.pi/agent/AGENTS.md
#   skills/<name>/       -> ~/.agents/skills/<name>   (one link per skill;
#                           other skills in that folder are left alone)
#   commands/            -> ~/.claude/commands
#   commands/            -> ~/.pi/agent/prompts
#   pi/mcp.json          -> ~/.pi/agent/mcp.json
#   pi/extensions/<file> -> ~/.pi/agent/extensions/<file>   (one link per file)
#
# Idempotent: a link that already points at the repo is left alone.
# A file or folder that gets replaced is moved to ~/.dotfiles-backup/<timestamp>/
# before the link is created.

set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd -P)"
BACKUP_ROOT="${HOME}/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
APPLY=0
BACKED_UP=0

case "${1:-}" in
  "") ;;
  --apply) APPLY=1 ;;
  -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
  *) echo "unknown option: $1 (use --apply or no option)" >&2; exit 2 ;;
esac

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
echo

link "$REPO/agents/AGENTS.md" "$HOME/.claude/CLAUDE.md"
link "$REPO/agents/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"

for skill_dir in "$REPO"/skills/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  link "${skill_dir%/}" "$HOME/.agents/skills/$name"
done

link "$REPO/commands" "$HOME/.claude/commands"
link "$REPO/commands" "$HOME/.pi/agent/prompts"
link "$REPO/pi/mcp.json" "$HOME/.pi/agent/mcp.json"

for ext in "$REPO"/pi/extensions/*.ts; do
  [ -f "$ext" ] || continue
  link "$ext" "$HOME/.pi/agent/extensions/$(basename "$ext")"
done

if [ "$BACKED_UP" = 1 ]; then
  echo
  echo "backups: $BACKUP_ROOT"
fi
