#!/usr/bin/env bash
# Runs the coding-brain viewer in this pane (foreground; closing the pane stops it).
set -euo pipefail

echo "herdr-recall — starting the coding-brain viewer..."
echo "(first run may take a moment while npx fetches coding-brain)"
echo
exec npx -y coding-brain ui
