#!/usr/bin/env bash
# Check that pi's models.json keeps supportsMidConvoEffort on every magpie
# model in MODEL_IDS. Magpie regenerates models.json from its catalog, which
# drops the flag, and the thinking-block 400 error comes back.
#
# Usage:
#   scripts/check-pi-models.sh                 check only; exit 1 if any model lacks the flag
#   scripts/check-pi-models.sh --fix           add the flag to each model that lacks it, in
#                                              the current file. Magpie's other changes stay.
#   scripts/check-pi-models.sh --restore FILE  replace models.json with FILE, which must set
#                                              the flag on every model. Only for a missing or
#                                              broken models.json: it undoes every change
#                                              magpie made since FILE was saved.
#
# Both save the current file to ~/.dotfiles-backup first. --fix changes only
# the flag lines, then prints them. It refuses, leaving the file alone, if
# writing the file back would change anything else, such as its formatting.
#
# A copy for --restore is ~/.dotfiles-backup/models.json.good.
#
# Restarting pi or starting a new session is needed to load the changed file.

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

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

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

# add_flag FILE BACKUP: set the flag on each model in MODEL_IDS that lacks it,
# saving FILE to BACKUP before writing. Exit 0 if every model now has the flag,
# 1 if some model is absent from FILE (the others are still fixed), 3 if FILE
# was left alone: not JSON, written in a format this can't reproduce, or
# changed by another writer meanwhile.
add_flag() {
  python3 - "$1" "$2" "$PROVIDER" "${MODEL_IDS[@]}" <<'EOF'
import json, os, shutil, sys, tempfile
path, backup, provider, *model_ids = sys.argv[1:]
target = os.path.realpath(path)

def refuse(why):
    print(f"refusing: {why}; {path} is unchanged", file=sys.stderr)
    sys.exit(3)

def render(d):
    return json.dumps(d, indent=2, ensure_ascii=False)

with open(target, "rb") as f:
    raw = f.read()
try:
    data = json.loads(raw.decode("utf-8"))
except ValueError as e:
    refuse(f"it is not valid JSON ({e})")

# Writing back must reproduce the file byte for byte, so that the flag lines
# are the only change.
text = raw.decode("utf-8")
if text == render(data) + "\n":
    end = "\n"
elif text == render(data):
    end = ""
else:
    refuse("writing it back would change more than the flag lines; add the flag by hand")

def set_key(d, key, value):
    # Keep the keys sorted if they were, as magpie writes them.
    was_sorted = list(d) == sorted(d)
    d[key] = value
    if was_sorted:
        items = sorted(d.items())
        d.clear()
        d.update(items)

models = data.get("providers", {}).get(provider, {}).get("models", [])
by_id = {m.get("id"): m for m in models if isinstance(m, dict)}
added, absent = [], []
for model_id in model_ids:
    m = by_id.get(model_id)
    if m is None:
        absent.append(model_id)
        continue
    compat = m.get("compat")
    if not isinstance(compat, dict):
        compat = {}
        set_key(m, "compat", compat)
    if compat.get("supportsMidConvoEffort") is not True:
        set_key(compat, "supportsMidConvoEffort", True)
        added.append(model_id)

if added:
    with open(target, "rb") as f:
        if f.read() != raw:
            refuse("another program changed it meanwhile; run again")
    os.makedirs(os.path.dirname(backup), exist_ok=True)
    shutil.copy2(target, backup)
    print(f"current file saved to {backup}")
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(target), prefix=".models.json.")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.write(render(data) + end)
    shutil.copymode(target, tmp)
    os.replace(tmp, target)
for model_id in added:
    print(f"added: supportsMidConvoEffort on {provider}/{model_id}")
for model_id in absent:
    print(f"absent: {provider}/{model_id} is not in {path}, so it can't get the flag", file=sys.stderr)
sys.exit(1 if absent else 0)
EOF
}

MODE="check"
RESTORE=""
case "${1:-}" in
  "") ;;
  --fix) MODE="fix" ;;
  --restore) MODE="restore"; RESTORE="${2:?--restore needs a FILE}" ;;
  -h|--help) usage; exit 0 ;;
  *) echo "unknown option: $1 (use --fix, --restore FILE or no option)" >&2; exit 2 ;;
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

SAVED="$BACKUP_DIR/models.json.pre-check-$(date +%Y%m%d-%H%M%S)"

case "$MODE" in
  check)
    echo "run '$0 --fix' to add the flag to the current file"
    echo "(if models.json is missing or broken: '$0 --restore $BACKUP_DIR/models.json.good')"
    exit 1
    ;;
  fix)
    if [ ! -f "$MODELS" ]; then
      echo "$MODELS is missing; use --restore FILE instead" >&2
      exit 1
    fi
    rc=0
    add_flag "$MODELS" "$SAVED" || rc=$?
    if [ -e "$SAVED" ]; then
      echo "changes (diff $SAVED $MODELS):"
      diff "$SAVED" "$MODELS" || true
      echo "start a new pi session to load it"
    fi
    exit "$rc"
    ;;
esac

if ! RESTORE_MISSING="$(missing_flag "$RESTORE")"; then
  echo "refusing: $RESTORE does not set the flag on: ${RESTORE_MISSING//$'\n'/, }" >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"
if [ -e "$MODELS" ]; then
  cp -p "$MODELS" "$SAVED"
  echo "current file saved to $SAVED"
fi
cp -p "$RESTORE" "$MODELS"
echo "restored $MODELS from $RESTORE"
echo "start a new pi session to load it"
