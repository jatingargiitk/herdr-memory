#!/usr/bin/env bash
# Shared helpers. Sourced by the other scripts; not executable on its own.

# The npm spec used for every call. Pinned at 0.1.12: `--no-hooks` landed in
# 0.1.7, the full-brain starter compile in 0.1.10, and 0.1.12 replaced it with
# the single-turn fan-out (digests + topics + STATE via parallel calls, cost
# receipt, meta-session filter, per-project corpus floor) plus the
# leads-not-findings injection wrapper. The CLI ignores unknown flags rather
# than erroring, so an older version fails silently rather than loudly.
# Override with CODING_BRAIN_PKG to test against a local build.
CB_PKG="${CODING_BRAIN_PKG:-coding-brain@^0.1.12}"

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
  # 30-minute debounce: every harvest is one call on a good model, so cost
  # scales with frequency, not tier. Fewer, meatier harvests are also better
  # digests — each one sees a whole chunk of work instead of a fragment.
  cat > "$CONFIG_FILE" <<'EOF'
{
  "auto": true,
  "debounce_minutes": 30,
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
  local workspace="$1" brain="$1/.coding-brain"
  if [ -d "$brain" ]; then
    printf '%s\n' "$brain"
    return 0
  fi

  # First time: scaffold the brain in this exact workspace (don't walk up)
  ( cd "$workspace" && CODING_BRAIN_NO_UI=1 npx -y "$CB_PKG" init \
      --yes --hooks-only --no-hooks --no-ui ) >/dev/null 2>&1

  # Initialize brain structure: create STATE.md and sessions/topics dirs
  if [ -n "$brain" ]; then
    mkdir -p "$brain/sessions" "$brain/topics"
    if [ ! -f "$brain/STATE.md" ]; then
      cat > "$brain/STATE.md" << 'EOF'
# Brain State

**Created:** $(date)

## Summary
Fresh brain, ready to learn from your agent sessions.

## Next Steps
- Run agents (Claude Code, Cursor, Codex, etc.)
- Brain auto-saves on every session finish
- Optionally backfill past sessions to jump-start learning
EOF
    fi
  fi

  # Interactive setup on first agent finish (not in cron/CI environments)
  if [ -n "$brain" ] && [ -t 0 ]; then
    notify "Brain created. Import past sessions? (waiting for response...)"
    printf '\nImport past sessions to give brain a head start? [y/N] '
    read -r -t 15 response 2>/dev/null || response="N"
    case "$response" in
      y|Y)
        printf 'Importing... (this takes 1-3 min)\n'
        if ( cd "$workspace" && CODING_BRAIN_NO_UI=1 npx -y "$CB_PKG" init --yes --no-hooks --no-ui 2>&1 ) >> "$STATE_DIR/harvest.log"; then
          notify "Brain ready. Auto-save is on."
        else
          notify "Backfill skipped, but brain is ready."
        fi
        ;;
      *)
        printf 'Skipped. Brain learns from now on.\n'
        notify "Brain ready. Auto-save is on."
        ;;
    esac
  fi

  printf '%s\n' "$brain"
}

notify() {
  "$HERDR_BIN" notification show "$1" >/dev/null 2>&1 || true
}
