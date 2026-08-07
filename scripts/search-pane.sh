#!/usr/bin/env bash
# Interactive search popup: type a query, get ranked results from past sessions.
# Empty query (or Ctrl-C / Ctrl-D) closes the popup.
set -uo pipefail

# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

if ! find_brain >/dev/null; then
  print_setup_hint
  printf '\nPress Enter to close. '
  IFS= read -r _ || true
  exit 0
fi

while true; do
  printf '\nsearch past sessions (empty to close): '
  IFS= read -r query || exit 0
  [ -z "$query" ] && exit 0
  # shellcheck disable=SC2086 — word-splitting the query into terms is intended
  npx -y coding-brain search $query 2>&1 | less -RFX
done
