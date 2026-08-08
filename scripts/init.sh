#!/usr/bin/env bash
# Initialize the brain: scaffold + optional backfill.
# Run after `herdr plugin install` to set up with a single command.

set -uo pipefail

here="$(dirname "$0")"
# shellcheck source=lib.sh
. "$here/lib.sh"

ensure_config
mkdir -p "$STATE_DIR"
log_file="$STATE_DIR/harvest.log"

workspace=$(target_workspace)
echo "Setting up memory in: $workspace"

if [ -d "$workspace/.coding-brain" ]; then
  echo "✓ Memory already exists here."
  exit 0
fi

echo "Creating memory store..."
if ! brain=$(ensure_brain "$workspace"); then
  echo "✗ Failed to create memory."
  notify "Setup failed — check if Node is installed."
  exit 1
fi

echo "✓ Memory created."
echo ""
echo "Do you want to import past sessions to give the brain a head start?"
echo "(This reads earlier work and costs one model call, ~1-3 min)"
printf "[y/N] "
read -r response

case "$response" in
  y|Y)
    echo "Importing past sessions..."
    if ( cd "$workspace" && npx -y "$CB_PKG" harvest --backfill 2>&1 ) >> "$log_file"; then
      echo "✓ Brain now knows about your past work."
      notify "Brain is ready. Auto-save is on. Use herdr-memory.search to ask it things."
    else
      echo "✗ Backfill didn't work, but that's OK — brain starts learning from now on."
      notify "Setup complete. Brain will learn from your next session."
    fi
    ;;
  *)
    echo "Skipped. Brain will learn from your next session forward."
    notify "Brain is ready. Use herdr-memory.search to ask it things."
    ;;
esac

exit 0
