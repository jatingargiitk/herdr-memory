#!/usr/bin/env bash
# Saves the newest unsaved agent session into the brain (`coding-brain harvest`).
#
# Two invocation modes:
#   --manual                  from the "remember-now" action: always runs, shows a notification
#   (no args, event hook)     from pane.agent_status_changed: runs only when an agent
#                             reaches "done" or "idle", debounced to once per 10 minutes
set -uo pipefail

herdr_bin="${HERDR_BIN_PATH:-herdr}"
state_dir="${HERDR_PLUGIN_STATE_DIR:-${TMPDIR:-/tmp}/herdr-memory}"
mkdir -p "$state_dir"
stamp_file="$state_dir/last-harvest-epoch"
log_file="$state_dir/harvest.log"
DEBOUNCE_SECONDS=600

manual=0
[ "${1:-}" = "--manual" ] && manual=1

if [ "$manual" -eq 0 ]; then
  # Only react when an agent finishes (status "done" or settles to "idle").
  status=$(printf '%s' "${HERDR_PLUGIN_EVENT_JSON:-}" | python3 -c '
import json, sys
try:
    payload = json.load(sys.stdin)
except Exception:
    sys.exit(0)
def find_status(node):
    if isinstance(node, dict):
        for key, value in node.items():
            if key == "status" and isinstance(value, str):
                return value
            found = find_status(value)
            if found:
                return found
    elif isinstance(node, list):
        for item in node:
            found = find_status(item)
            if found:
                return found
    return None
print(find_status(payload) or "")
' 2>/dev/null)
  case "$status" in
    done|idle) ;;
    *) exit 0 ;;
  esac

  now=$(date +%s)
  last=$(cat "$stamp_file" 2>/dev/null || echo 0)
  [ $((now - last)) -lt "$DEBOUNCE_SECONDS" ] && exit 0
  echo "$now" > "$stamp_file"
fi

{
  echo "── $(date '+%Y-%m-%d %H:%M:%S') harvest (manual=$manual, status=${status:-n/a})"
  npx -y coding-brain harvest 2>&1
  rc=$?
  echo "── exit $rc"
} >> "$log_file"

if [ "$manual" -eq 1 ]; then
  if [ "${rc:-1}" -eq 0 ]; then
    "$herdr_bin" notification show "Session saved to your coding brain." >/dev/null 2>&1 || true
  else
    "$herdr_bin" notification show "Saving session failed — see harvest.log in the plugin state dir." >/dev/null 2>&1 || true
  fi
fi

exit 0
