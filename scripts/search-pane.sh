#!/usr/bin/env bash
# Search popup: type a question, get ranked answers from past sessions.
# Empty query (or Ctrl-C / Ctrl-D) closes the popup.
set -uo pipefail

# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

workspace=$(target_workspace)

if ! find_brain "$workspace" >/dev/null; then
  cat <<EOF
Nothing remembered here yet.

herdr-memory saves each session when your agents finish working, so this
fills up on its own as you use this folder — there's nothing to set up.

To pull in sessions from before you installed it, run the
"Learn from earlier sessions" action.

EOF
  printf 'Press Enter to close. '
  IFS= read -r _ || true
  exit 0
fi

cd "$workspace" || exit 1

while true; do
  printf '\nask about past sessions (empty to close): '
  IFS= read -r query || exit 0
  [ -z "$query" ] && exit 0
  # shellcheck disable=SC2086 — word-splitting the query into terms is intended
  npx -y "$CB_PKG" search $query 2>&1 | less -RFX
done
