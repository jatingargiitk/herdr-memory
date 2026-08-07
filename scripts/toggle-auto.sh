#!/usr/bin/env bash
# Turns automatic saving on or off.
set -uo pipefail

# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

ensure_config

if [ "$(cfg auto true)" = "true" ]; then
  set_cfg auto false
  notify "Automatic saving OFF — use \"Save this session now\" when you want it."
else
  set_cfg auto true
  notify "Automatic saving ON — sessions are saved when your agents finish."
fi
