#!/usr/bin/env bash
# Check that pi's models.json keeps supportsMidConvoEffort on every magpie
# model in MODEL_IDS. Magpie regenerates models.json from its catalog, which
# drops the flag, and the thinking-block 400 error comes back.
#
# Usage:
#   scripts/check-pi-models.sh                 check only; exit 1 if any model lacks the flag
#   scripts/check-pi-models.sh --restore FILE  if any model lacks the flag, replace models.json
#                                              with FILE, which must set the flag on every
#                                              model. The current file is saved to
#                                              ~/.dotfiles-backup first.
#
# The known-good copy is ~/.dotfiles-backup/models.json.good. Restoring it also
# drops any model or price magpie has changed since that copy was saved, so
# refresh it (cp -p ~/.pi/agent/models.json ~/.dotfiles-backup/models.json.good)
# whenever this script reports ok after a magpie update.
#
# Restarting pi or starting a new session is needed to load the restored file.

set -euo pipefail

MODELS="${HOME}/.pi/agent/models.json"
BACKUP_DIR="${HOME}/.dotfiles-backup"
PROVIDER="magpie"
MODEL_IDS=(
  "anthropic/claude-opus-5-5"
  "anthropic/claude-sonnet-5-5"
  "anthropic/claude-fable-5-1"
  "anthropic/claude-haiku-5-5"
)

# missing_flag FILE: print each model in MODEL_IDS that lacks the flag in FILE,
# one per line. Exit 0 if none lacks it, 1 otherwise. A model absent from FILE,
# or a FILE that can't be read, counts as lacking it.
missing_flag() {
  python3 - "$1" "$PROVIDER" "${MODEL_IDS[@]}" <<'EOF'
import json, sys
path, provider, *model_ids = sys.argv[1:]
try:
    d = json.load(open(path))
except (OSError, ValueError):
    d = {}
flagged = {
    m.get("id")
    for m in d.get("providers", {}).get(provider, {}).get("models", [])
    if (m.get("compat") or {}).get("supportsMidConvoEffort") is True
}
missing = [i for i in model_ids if i not in flagged]
for i in missing:
    print(i)
sys.exit(1 if missing else 0)
EOF
}

RESTORE=""
case "${1:-}" in
  "") ;;
  --restore) RESTORE="${2:?--restore needs a FILE}" ;;
  -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
  *) echo "unknown option: $1 (use --restore FILE or no option)" >&2; exit 2 ;;
esac

if MISSING="$(missing_flag "$MODELS")"; then
  for id in "${MODEL_IDS[@]}"; do
    echo "ok: supportsMidConvoEffort is set on $PROVIDER/$id"
  done
  exit 0
fi

while IFS= read -r id; do
  echo "missing: supportsMidConvoEffort is not set on $PROVIDER/$id in $MODELS"
done <<< "$MISSING"

if [ -z "$RESTORE" ]; then
  echo "run with --restore FILE to replace it with a copy that sets the flag"
  echo "(the known-good copy is $BACKUP_DIR/models.json.good)"
  exit 1
fi

if ! RESTORE_MISSING="$(missing_flag "$RESTORE")"; then
  echo "refusing: $RESTORE does not set the flag on: ${RESTORE_MISSING//$'\n'/, }" >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"
if [ -e "$MODELS" ]; then
  SAVED="$BACKUP_DIR/models.json.pre-check-$(date +%Y%m%d-%H%M%S)"
  cp -p "$MODELS" "$SAVED"
  echo "current file saved to $SAVED"
fi
cp -p "$RESTORE" "$MODELS"
echo "restored $MODELS from $RESTORE"
echo "start a new pi session to load it"
