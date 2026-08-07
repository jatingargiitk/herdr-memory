# herdr-memory

**Your agents forget everything. This remembers.**

A [Herdr](https://herdr.dev) plugin that watches the agents you run in your panes
and keeps a compiled memory of what they did — so you can ask "how did we fix
that?" three weeks later and get an answer instead of scrolling.

```
┌─ claude · api refactor ───────┬─ Recall ─────────────────────┐
│ ✓ done — 14 files             │ how did we fix the auth      │
│                               │ timeout?                     │
│                               │                              │
│  saved to memory ↴            │ Jul 22 · the retry wrapper   │
│                               │ swallowed 401s; fix was to   │
│                               │ re-raise before the backoff  │
└───────────────────────────────┴──────────────────────────────┘
```

## Why it's a Herdr plugin

Memory tools bolt onto one coding agent — they read Claude Code's transcripts, or
Cursor's. Herdr already knows *every* agent you're running, which folder each one
is in, and when each one finishes. That's the right vantage point: the memory is
built around your workspace, not around one vendor's tool.

## Install

```sh
herdr plugin install jatingargiitk/herdr-memory
```

That's the whole setup. No init, no config, no account. The memory store is
created the first time an agent finishes, in the folder that agent was working
in. Needs Node (it calls the [`coding-brain`](https://www.npmjs.com/package/coding-brain)
CLI via `npx`).

## Use

**Auto mode (on by default).** When an agent in any pane finishes, herdr-memory
asks Herdr which folder that agent was working in and saves the session there —
what happened, what got decided, what was learned. Debounced per folder, so
several agents finishing at once don't stack up, and a busy worktree never mutes
a quiet one.

**Manual.** Actions, also invokable from the CLI:

```sh
herdr plugin action invoke search --plugin herdr-memory       # ask about past sessions
herdr plugin action invoke open-ui --plugin herdr-memory      # the viewer, in a split
herdr plugin action invoke save-now --plugin herdr-memory     # save right now
herdr plugin action invoke toggle-auto --plugin herdr-memory  # auto mode on/off
herdr plugin action invoke backfill --plugin herdr-memory     # learn from earlier sessions
```

Bind the ones you use in `~/.config/herdr/config.toml`:

```toml
[[keys.command]]
key = "prefix+/"
type = "plugin_action"
command = "herdr-memory.search"
description = "ask about past sessions"

[[keys.command]]
key = "prefix+b"
type = "plugin_action"
command = "herdr-memory.open-ui"
description = "memory viewer"
```

**Learn from earlier sessions** is the one thing that isn't automatic. It reads
the agent sessions you had *before* installing this and compiles a starting
picture of your projects. It costs a model call (~1-3 min), so it only ever runs
when you ask for it, and it confirms before reading anything.

## Configuration

`$HERDR_PLUGIN_CONFIG_DIR/config.json` (defaults shown; the directory is printed
by `herdr plugin config-dir herdr-memory`):

```jsonc
{
  "auto": true,             // save automatically when agents finish
  "debounce_minutes": 10,   // minimum gap between saves in the same folder
  "workspace_root": null    // pin every save to one folder instead of the agent's
}
```

## How it works

- A `pane.agent_status_changed` event hook fires when an agent reaches `done` or
  `idle`. It reads `herdr api snapshot` to find that pane's working directory —
  the hook process's own cwd is not it, since Herdr runs agents across many
  folders and worktrees at once.
- Saving is `coding-brain harvest` in that folder. `coding-brain` holds a mutex
  while it works, so a save triggered here and one triggered by an agent's own
  hooks can never double up.
- Setup is `coding-brain init --no-hooks`, which builds the store without
  touching your Claude Code or Cursor config. Herdr's events are the only
  trigger this plugin installs — nothing is changed outside Herdr's own
  directories and the memory folder itself.
- No build step, no bundled binaries, no background daemon.

## Limits, honestly

Saving reads the transcript the agent itself writes to disk, which today means
Claude Code, Cursor, and Codex. Herdr detects agents beyond those — when one of
them finishes, the memory folder is created but there's no transcript to read
yet. Reading pane output directly through `herdr agent read`, so *any* agent in a
pane gets remembered, is the next thing being built.

## License

MIT.
