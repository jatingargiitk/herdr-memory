#!/usr/bin/env bash
# Saves what an agent just did, into the memory for the folder it was working in.
#
#   (no args)   event hook on pane.agent_status_changed — herdr tells us which pane
#               finished; we ask herdr which folder that pane was working in, and
#               save there. Honours the `auto` config flag, debounced per folder.
#   --manual    the "Save this session now" action — always runs, reports via notification
#
# Creates the memory store on first use, so there is no setup step.
set -uo pipefail

here="$(dirname "$0")"
# shellcheck source=lib.sh
. "$here/lib.sh"

ensure_config
mkdir -p "$STATE_DIR"
log_file="$STATE_DIR/harvest.log"

manual=0
[ "${1:-}" = "--manual" ] && manual=1
status=""; agent=""; workspace=""; pane_id=""

if [ "$manual" -eq 0 ]; then
  [ "$(cfg auto true)" = "true" ] || exit 0

  # Ask herdr where this agent actually is. The hook process's cwd is not it —
  # herdr may run many agents across different folders and worktrees at once.
  snapshot="$STATE_DIR/snapshot.$$.json"
  "$HERDR_BIN" api snapshot > "$snapshot" 2>/dev/null || true
  resolved=$(printf '%s' "${HERDR_PLUGIN_EVENT_JSON:-}" | python3 "$here/resolve.py" "$snapshot" 2>/dev/null)
  rm -f "$snapshot"

  if [ -n "$resolved" ]; then
    while IFS='=' read -r key value; do
      case "$key" in
        workspace) workspace="$value" ;;
        status) status="$value" ;;
        agent) agent="$value" ;;
        pane_id) pane_id="$value" ;;
      esac
    done <<< "$resolved"
  fi

  # Only react when an agent finishes (status "done", or settles to "idle").
  case "$status" in
    done|idle) ;;
    *) exit 0 ;;
  esac
fi

[ -n "$workspace" ] || workspace=$(target_workspace)
[ -d "$workspace" ] || exit 0

# Debounce per folder, not globally — an agent finishing in one worktree must not
# mute a different agent finishing in another.
if [ "$manual" -eq 0 ]; then
  debounce_minutes=$(cfg debounce_minutes 10)
  case "$debounce_minutes" in ''|*[!0-9]*) debounce_minutes=10 ;; esac
  slug=$(printf '%s' "$workspace" | tr -c 'A-Za-z0-9' '-')
  stamp_file="$STATE_DIR/last-save.$slug"
  now=$(date +%s)
  last=$(cat "$stamp_file" 2>/dev/null || echo 0)
  case "$last" in ''|*[!0-9]*) last=0 ;; esac
  [ $((now - last)) -lt $((debounce_minutes * 60)) ] && exit 0
  echo "$now" > "$stamp_file"
fi

if ! brain=$(ensure_brain "$workspace"); then
  echo "── $(date '+%Y-%m-%d %H:%M:%S') could not create memory in $workspace" >> "$log_file"
  [ "$manual" -eq 1 ] && notify "Couldn't set up memory here — is Node installed?"
  exit 0
fi

{
  echo "── $(date '+%Y-%m-%d %H:%M:%S') save (manual=$manual, agent=${agent:-?}, pane=${pane_id:-?}, status=${status:-n/a})"
  echo "   folder: $workspace"
  ( cd "$workspace" && npx -y "$CB_PKG" harvest 2>&1 )
  echo "── exit $?"
} >> "$log_file"

if [ "$manual" -eq 1 ]; then
  if tail -1 "$log_file" | grep -q "exit 0"; then
    notify "Session saved to memory."
  else
    notify "Saving failed — see harvest.log ($STATE_DIR)."
  fi
fi

exit 0
