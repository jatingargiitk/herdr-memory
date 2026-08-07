#!/usr/bin/env bash
# Opens one of this plugin's panes via the herdr socket API.
# Usage: open-pane.sh <entrypoint-id>
set -euo pipefail

entrypoint="${1:?usage: open-pane.sh <entrypoint-id>}"
herdr_bin="${HERDR_BIN_PATH:-herdr}"

exec "$herdr_bin" plugin pane open \
  --plugin "${HERDR_PLUGIN_ID:-herdr-recall}" \
  --entrypoint "$entrypoint" \
  --focus
