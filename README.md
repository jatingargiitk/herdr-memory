# herdr-memory

Your coding agents' long-term memory, inside [Herdr](https://herdr.dev).

Powered by [coding-brain](https://www.npmjs.com/package/coding-brain): every agent
session gets distilled into a compact, compiled record of what happened, what was
decided, and what was learned — so your next session (and your next agent) starts
with context instead of amnesia.

## What it does

- **Saves sessions automatically.** Whenever an agent pane finishes working,
  the newest unsaved session is distilled into the brain (at most once per 10 minutes).
- **Search past sessions.** A popup where you ask "how did we fix X?" and get
  ranked answers from everything your agents have done — not raw transcript dumps.
- **A viewer pane.** See what the brain knows: the live record of your projects,
  recent sessions, and what was learned from each.

## Install

```
herdr plugin install jatingargiitk/herdr-memory
```

Requires Node.js (the plugin calls the `coding-brain` CLI via `npx`).

Then, once per folder you work in:

```
npx coding-brain init
```

That scans the agent sessions you already have there, builds a starting picture of
your projects, and turns on automatic saving. Until you run it, the plugin's panes
tell you so and the automatic saving stays quiet — nothing breaks, it just has
nothing to remember yet.

## Actions

Bind these in `~/.config/herdr/config.toml`:

```toml
[[keys.command]]
key = "prefix+b"
type = "plugin_action"
command = "herdr-memory.open-ui"
description = "open brain viewer"

[[keys.command]]
key = "prefix+/"
type = "plugin_action"
command = "herdr-memory.search"
description = "search past sessions"
```

| Action | What it does |
| --- | --- |
| `herdr-memory.open-ui` | Open the coding-brain viewer in a split pane |
| `herdr-memory.search` | Search past sessions in a popup |
| `herdr-memory.remember-now` | Save the newest session immediately |

## How it works

Thin shell wrappers around the `coding-brain` npm CLI — no bundled binaries, no
build step, nothing running in the background beyond Herdr's own event hooks.
Session data lives wherever coding-brain keeps it in your workspace; this plugin
stores only a debounce timestamp and a log under its Herdr state directory.
