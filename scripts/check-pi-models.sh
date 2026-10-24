#!/usr/bin/env bash
# Check that pi's models.json keeps supportsMidConvoEffort on magpie's
# anthropic/claude-haiku-5-5. Magpie regenerates models.json from its catalog,
# which drops the flag, and the thinking-block 400 error comes back.
#
# Usage:
#   scripts/check-pi-models.sh                 check only; exit 1 if the flag is missing
#   scripts/check-pi-models.sh --restore FILE  if the flag is missing, replace models.json
#                                              with FILE, which must set the flag. The
#                                              current file is saved to ~/.dotfiles-backup first.
#
# Restarting pi or starting a new session is needed to load the restored file.

set -euo pipefail

MODELS="${HOME}/.pi/agent/models.json"
BACKUP_DIR="${HOME}/.dotfiles-backup"
PROVIDER="magpie"
MODEL_ID="anthropic/claude-haiku-5-5"

# has_flag FILE: exit 0 if FILE sets the flag on PROVIDER/MODEL_ID, 1 otherwise.
has_flag() {
  python3 - "$1" "$PROVIDER" "$MODEL_ID" <<'EOF'
import json, sys
path, provider, model_id = sys.argv[1:4]
try:
    d = json.load(open(path))
except (OSError, ValueError):
    sys.exit(1)
for m in d.get("providers", {}).get(provider, {}).get("models", []):
    if m.get("id") == model_id:
        sys.exit(0 if m.get("compat", {}).get("supportsMidConvoEffort") is True else 1)
sys.exit(1)
EOF
}

RESTORE=""
case "${1:-}" in
  "") ;;
  --restore) RESTORE="${2:?--restore needs a FILE}" ;;
  -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
  *) echo "unknown option: $1 (use --restore FILE or no option)" >&2; exit 2 ;;
esac

if has_flag "$MODELS"; then
  echo "ok: supportsMidConvoEffort is set on $PROVIDER/$MODEL_ID"
  exit 0
fi

echo "missing: supportsMidConvoEffort is not set on $PROVIDER/$MODEL_ID in $MODELS"

if [ -z "$RESTORE" ]; then
  echo "run with --restore FILE to replace it with a copy that sets the flag"
  exit 1
fi

if ! has_flag "$RESTORE"; then
  echo "refusing: $RESTORE does not set the flag" >&2
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
