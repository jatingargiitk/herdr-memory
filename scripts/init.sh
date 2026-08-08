#!/usr/bin/env bash
# Interactive brain initialization: prompt to scaffold brain and backfill.
# Runs when user invokes: herdr plugin action invoke init --plugin herdr-memory
# This is the interactive alternative to silent auto-scaffolding on first harvest.

set -uo pipefail

here="$(dirname "$0")"
# shellcheck source=lib.sh
. "$here/lib.sh"

ensure_config
mkdir -p "$STATE_DIR"

workspace=$(target_workspace)

# Check if brain already exists
if brain=$(find_brain "$workspace"); then
  echo "✓ Brain already exists at: $brain"
  echo ""
  echo "Want to update it with past sessions?"
  printf "[y/N] "
  read -r -t 15 response 2>/dev/null || response="N"
  case "$response" in
    y|Y)
      printf '\nImporting past sessions... (this takes 1-3 min)\n'
      if ( cd "$workspace" && CODING_BRAIN_NO_UI=1 npx -y "$CB_PKG" init --yes --no-hooks --no-ui 2>&1 ); then
        echo "✓ Brain updated with your past work."
      else
        echo "⚠ Backfill skipped, but brain is ready."
      fi
      ;;
    *)
      echo "Skipped. Brain will continue learning from now on."
      ;;
  esac
  exit 0
fi

# First-time: scaffold the brain
echo "Setting up brain in: $workspace"
echo ""

if ! brain=$(ensure_brain "$workspace"); then
  echo "✗ Could not create brain. Is Node installed?"
  exit 1
fi

echo ""
echo "✓ Brain created!"
echo ""
echo "Do you want to import your past agent sessions?"
echo "(This reads earlier work and costs one model call, ~1-3 min)"
printf "[y/N] "
read -r -t 15 response 2>/dev/null || response="N"

case "$response" in
  y|Y)
    printf '\nImporting past sessions... (this takes 1-3 min)\n'
    if ( cd "$workspace" && CODING_BRAIN_NO_UI=1 npx -y "$CB_PKG" init --yes --no-hooks --no-ui 2>&1 ); then
      echo ""
      echo "✓ Brain now knows about your past work."
      echo "Auto-save is ON — brain learns from every agent session."
    else
      echo ""
      echo "⚠ Backfill skipped, but brain is ready to learn from now on."
      echo "Auto-save is ON."
    fi
    ;;
  *)
    echo "Skipped. Brain will learn from your sessions going forward."
    echo "Auto-save is ON."
    ;;
esac

exit 0
