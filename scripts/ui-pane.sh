#!/usr/bin/env bash
# Runs the coding-brain viewer in this pane (foreground; closing the pane stops it).
set -uo pipefail

# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

workspace=$(target_workspace)

if ! brain=$(ensure_brain "$workspace"); then
  echo "Couldn't set up memory in $workspace — is Node installed?"
  printf '\nPress Enter to close. '
  IFS= read -r _ || true
  exit 1
fi

cd "$workspace" || exit 1

echo "herdr-memory — starting the viewer..."
echo "(first run may take a moment while npx fetches coding-brain)"
echo
exec npx -y "$CB_PKG" ui
