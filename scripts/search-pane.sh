#!/usr/bin/env bash
# Interactive search popup: type a query, get ranked results from past sessions.
# Empty query (or Ctrl-C / Ctrl-D) closes the popup.
set -uo pipefail

while true; do
  printf '\nsearch past sessions (empty to close): '
  IFS= read -r query || exit 0
  [ -z "$query" ] && exit 0
  # shellcheck disable=SC2086 — word-splitting the query into terms is intended
  npx -y coding-brain search $query 2>&1 | less -RFX
done
