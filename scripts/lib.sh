#!/usr/bin/env bash
# Shared helpers. Sourced by the other scripts; not executable on its own.

# Walks up from $1 (default: cwd) looking for a .coding-brain directory.
# Prints the path and returns 0 if found; returns 1 if this workspace has no brain yet.
find_brain() {
  local dir="${1:-$PWD}"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.coding-brain" ]; then
      printf '%s\n' "$dir/.coding-brain"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

# Prints the first-run message shown in interactive panes when no brain exists.
print_setup_hint() {
  cat <<'EOF'
No memory has been set up for this folder yet.

herdr-memory remembers what your coding agents do, so you can ask about it
later. It needs one one-time setup step in this folder:

    npx coding-brain init

That scans the agent sessions you already have here, builds a starting
picture of your projects, and turns on automatic saving from then on.

Once it finishes, this pane will work.
EOF
}
