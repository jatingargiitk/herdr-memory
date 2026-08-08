# herdr-memory

**A brain that gets smarter as you work.**

A [Herdr](https://herdr.dev) plugin that watches every agent you run and builds a
**living brain** of your workspace — decisions, what worked, what failed, patterns
you've learned. Not a transcript dump. A compiled current state that stays fresh
as you work.

The brain **rewrites itself** as you work — every session distills into the current
truth, old facts get replaced, decisions compound. Three weeks in, you ask "how did
we do this?" and the brain gives you the *current* answer based on everything
since, not a stale log of what you said then.

## Why it's a Herdr plugin

Memory tools bolt onto one agent. Herdr knows *every* agent in your workspace,
which folder each works in, and when each finishes. That's the right place to build
a brain: around your workspace, not one vendor's tool. Every Claude Code, Cursor,
Codex, or custom agent you run feeds the same brain.

## Install

```sh
herdr plugin install jatingargiitk/herdr-memory
```

Then set up with one command:

```sh
herdr plugin action invoke init --plugin herdr-memory
```

This will:
1. Create your memory store
2. Prompt: **"Import past sessions to give the brain a head start?"**
   - Say `y` to read earlier work (~1-3 min, costs one model call)
   - Say `N` to skip (brain learns from your next session forward)

Or skip init and the brain auto-scaffolds when your first agent finishes.

## Use

**Auto mode (on by default).** When an agent finishes, the brain distills what
happened into its current knowledge base. Debounced per folder so a busy worktree
doesn't mute a quiet one.

**Manual actions:**

```sh
herdr plugin action invoke search --plugin herdr-memory       # ask the brain anything
herdr plugin action invoke open-ui --plugin herdr-memory      # see the brain viewer
herdr plugin action invoke save-now --plugin herdr-memory     # harvest right now
herdr plugin action invoke toggle-auto --plugin herdr-memory  # auto mode on/off
herdr plugin action invoke backfill --plugin herdr-memory     # import earlier sessions
```

Bind them in `~/.config/herdr/config.toml`:

```toml
[[keys.command]]
key = "prefix+/"
type = "plugin_action"
command = "herdr-memory.search"
description = "ask the brain"

[[keys.command]]
key = "prefix+b"
type = "plugin_action"
command = "herdr-memory.open-ui"
description = "brain viewer"
```

## Configuration

`$HERDR_PLUGIN_CONFIG_DIR/config.json` (directory: `herdr plugin config-dir herdr-memory`):

```jsonc
{
  "auto": true,             // auto-save when agents finish
  "debounce_minutes": 10,   // minimum gap between saves in the same folder
  "workspace_root": null    // pin all saves to one folder (instead of per-agent)
}
```

## How it works

- A `pane.agent_status_changed` hook fires when an agent reaches `done` or `idle`
- Queries `herdr api snapshot` to find that pane's working folder (not the hook's cwd)
- Runs `coding-brain harvest` in that folder: distills the session into current truth
- Brain stays fresh: old facts are replaced, not appended to
- No build, no daemon, no external config

## Why the brain stays current

Unlike transcript search tools that grow stale as they pile up, this brain
**recompiles itself per harvest**. Every session:

- Reads the transcript
- Compares against what the brain already knows
- Replaces outdated facts with new ones
- Adds decisions and gotchas only once
- Commits to git so you can see what changed

This is the same model OpenAI, Anthropic, and Google landed on for background
memory consolidation this year: bigger pile ≠ better memory. Cleaner pile is.

## Limits

The brain reads transcript files agents write (Claude Code, Cursor, Codex). For
other Herdr agents, the folder is created but no transcript is read yet. Support
for agent-agnostic transcript capture (reading pane output via `herdr agent read`)
is planned.

## License

MIT.
