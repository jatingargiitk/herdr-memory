#!/usr/bin/env bash
# Shared helpers. Sourced by the other scripts; not executable on its own.

# The npm spec used for every call. Pinned: `--no-hooks` (which keeps us from
# touching the user's editor config) landed in 0.1.7, and the CLI ignores unknown
# flags rather than erroring — so an older version would silently install hooks.
# Override with CODING_BRAIN_PKG to test against a local build.
CB_PKG="${CODING_BRAIN_PKG:-coding-brain@^0.1.7}"

CONFIG_DIR="${HERDR_PLUGIN_CONFIG_DIR:-${TMPDIR:-/tmp}/herdr-memory-config}"
STATE_DIR="${HERDR_PLUGIN_STATE_DIR:-${TMPDIR:-/tmp}/herdr-memory-state}"
CONFIG_FILE="$CONFIG_DIR/config.json"
HERDR_BIN="${HERDR_BIN_PATH:-herdr}"

# Walks up from $1 (default: cwd) looking for a .coding-brain directory.
# Prints the path and returns 0 if found; 1 if this folder has no memory yet.
find_brain() {
  local dir="${1:-$PWD}"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.coding-brain" ]; then
      printf '%s\n' "$dir/.coding-brain"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

# Writes the default config on first use. Never overwrites an existing file.
ensure_config() {
  [ -f "$CONFIG_FILE" ] && return 0
  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG_FILE" <<'EOF'
{
  "auto": true,
  "debounce_minutes": 10,
  "workspace_root": null
}
EOF
}

# cfg <key> <default> — reads a value out of config.json, falling back on any error.
cfg() {
  local key="$1" fallback="$2"
  [ -f "$CONFIG_FILE" ] || { printf '%s\n' "$fallback"; return 0; }
  python3 - "$CONFIG_FILE" "$key" "$fallback" <<'PY' 2>/dev/null || printf '%s\n' "$fallback"
import json, sys
path, key, fallback = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(path) as fh:
        value = json.load(fh).get(key)
except Exception:
    value = None
if value is None:
    print(fallback)
elif isinstance(value, bool):
    print("true" if value else "false")
else:
    print(value)
PY
}

# set_cfg <key> <json-literal> — updates one key in config.json.
set_cfg() {
  ensure_config
  python3 - "$CONFIG_FILE" "$1" "$2" <<'PY'
import json, sys
path, key, raw = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(path) as fh:
        data = json.load(fh)
except Exception:
    data = {}
try:
    data[key] = json.loads(raw)
except ValueError:
    data[key] = raw
with open(path, "w") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
PY
}

# The folder a session belongs to. Prefers an explicit config override, then the
# workspace herdr reports for the event, then the pane's own cwd.
target_workspace() {
  local configured
  configured=$(cfg workspace_root "")
  if [ -n "$configured" ] && [ "$configured" != "null" ] && [ -d "$configured" ]; then
    printf '%s\n' "$configured"
    return 0
  fi
  printf '%s\n' "$PWD"
}

# Creates the memory store if this folder has none. Scaffold only: no model
# calls, no browser, no prompts, and `--no-hooks` leaves the user's editor config
# alone — herdr's own agent events are the trigger here, so installing a second
# set of hooks would just duplicate work. Prints the brain path on success.
ensure_brain() {
  local workspace="$1" brain
  if brain=$(find_brain "$workspace"); then
    printf '%s\n' "$brain"
    return 0
  fi

  # First time: scaffold the brain
  ( cd "$workspace" && CODING_BRAIN_NO_UI=1 npx -y "$CB_PKG" init \
      --yes --hooks-only --no-hooks --no-ui ) >/dev/null 2>&1
  brain=$(find_brain "$workspace")

  # Offer to backfill past sessions (first-time setup only)
  if [ -n "$brain" ] && [ -t 0 ]; then
    printf 'Memory created. Import past sessions to give the brain a head start? [y/N] '
    read -r -t 10 response 2>/dev/null || response="N"
    case "$response" in
      y|Y)
        ( cd "$workspace" && npx -y "$CB_PKG" harvest --backfill 2>&1 ) \
          && notify "Brain imported past sessions." \
          || notify "Backfill skipped (optional)."
        ;;
    esac
  fi

  printf '%s\n' "$brain"
}

notify() {
  "$HERDR_BIN" notification show "$1" >/dev/null 2>&1 || true
}
