# herdr-recall

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
herdr plugin install jatingargiitk/herdr-recall
```

Requires Node.js (the plugin calls the `coding-brain` CLI via `npx`). If you have
never set up coding-brain in a workspace, run `npx coding-brain init` there first —
the plugin saves and searches sessions, it doesn't do first-time setup for you.

## Actions

Bind these in `~/.config/herdr/config.toml`:

```toml
[[keys.command]]
key = "prefix+b"
type = "plugin_action"
command = "herdr-recall.open-ui"
description = "open brain viewer"

[[keys.command]]
key = "prefix+/"
type = "plugin_action"
command = "herdr-recall.search"
description = "search past sessions"
```

| Action | What it does |
| --- | --- |
| `herdr-recall.open-ui` | Open the coding-brain viewer in a split pane |
| `herdr-recall.search` | Search past sessions in a popup |
| `herdr-recall.remember-now` | Save the newest session immediately |

## How it works

Thin shell wrappers around the `coding-brain` npm CLI — no bundled binaries, no
build step, nothing running in the background beyond Herdr's own event hooks.
Session data lives wherever coding-brain keeps it in your workspace; this plugin
stores only a debounce timestamp and a log under its Herdr state directory.
