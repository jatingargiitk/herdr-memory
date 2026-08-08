#!/usr/bin/env bash
# First-run initialization: scaffold brain and prompt for backfill.
# Runs once on first herdr startup after plugin install (via startup_commands).
# Safe to re-run; detects if already initialized and does nothing.

set -uo pipefail

here="$(dirname "$0")"
# shellcheck source=lib.sh
. "$here/lib.sh"

ensure_config
mkdir -p "$STATE_DIR"

workspace=$(target_workspace)

# Check if brain already exists (if yes, skip — already initialized)
if [ -d "$workspace/.coding-brain" ]; then
  exit 0
fi

# First-time setup: create brain (ensure_brain handles scaffolding + prompting)
if ! brain=$(ensure_brain "$workspace"); then
  notify "⚠️ herdr-memory" "Brain setup failed. Try 'herdr plugin action invoke init'."
  exit 1
fi

exit 0
