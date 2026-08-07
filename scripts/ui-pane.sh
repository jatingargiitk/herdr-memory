#!/usr/bin/env bash
# Runs the coding-brain viewer in this pane (foreground; closing the pane stops it).
set -uo pipefail

# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

if ! find_brain >/dev/null; then
  print_setup_hint
  printf '\nPress Enter to close. '
  IFS= read -r _ || true
  exit 0
fi

echo "herdr-memory — starting the viewer..."
echo "(first run may take a moment while npx fetches coding-brain)"
echo
exec npx -y coding-brain ui
