#!/usr/bin/env bash
# Optional: read the agent sessions you already had before installing this, and
# compile them into a starting picture of your projects.
#
# This one costs something — it reads your past transcripts and makes a model
# call — so it is never automatic. It runs in a pane, interactively, and
# coding-brain does its own consent prompt on top.
set -uo pipefail

# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

workspace=$(target_workspace)
cd "$workspace" || exit 1

cat <<EOF
Learn from earlier sessions
───────────────────────────
Folder: $workspace

herdr-memory normally starts remembering from the moment you install it.
This reads the agent sessions you already had here *before* that, and builds
a starting picture of your projects from them.

It reads those past transcripts and makes one model call (roughly 1-3 minutes),
so it costs a little. You'll be shown what it found and asked before anything
is compiled. Nothing already saved is overwritten.

EOF

printf 'Continue? [y/N] '
IFS= read -r answer || answer=""
case "$answer" in
  y|Y|yes|Yes) ;;
  *) echo "Cancelled — nothing was read."; printf '\nPress Enter to close. '; IFS= read -r _ || true; exit 0 ;;
esac

echo
npx -y "$CB_PKG" init --no-ui
echo
printf 'Done. Press Enter to close. '
IFS= read -r _ || true
