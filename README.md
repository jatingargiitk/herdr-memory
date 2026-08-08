# herdr-memory

**A brain that gets smarter as you work.**

A [Herdr](https://herdr.dev) plugin that watches every agent you run and builds a
**living brain** of your workspace. Decisions, what worked, what failed, patterns
you've learned. Not a transcript dump. A compiled current state that stays fresh
as you work.

The brain **rewrites itself** as you work. Every session distills into the current
truth, old facts get replaced, decisions compound. Three weeks in, you ask "how did
we do this?" and the brain gives you the *current* answer based on everything
since, not a stale log of what you said then.

## Why it's a Herdr plugin

Memory tools bolt onto one agent. Herdr knows *every* agent in your workspace,
which folder each works in, and when each finishes. That's the right place to build
a brain: around your workspace, not one vendor's tool. Run Claude Code in the
morning and Cursor in the afternoon on the same folder, and both feed one brain —
neither tool can do that alone.

(Today that means Claude Code, Cursor, and Codex — the agents that write readable
transcripts. See [Limits](#limits).)

## Install

```sh
herdr plugin install jatingargiitk/herdr-memory
```

Then just work. The next time an agent finishes in a folder, the brain sets
itself up there and **compiles everything you've already done in it** — no init
step, no prompt to answer.

You'll get a notification:

```
🧠 Compiling your brain from recent sessions (~2-5 min)…
   ↓
🧠 Brain ready — compiled from your recent sessions.
```

Watch it happen if you want:

```sh
tail -f ~/.local/state/herdr/plugins/herdr-memory/harvest.log
```

## What the first compile actually does

It does **not** start you at zero. It reads the coding-agent transcripts already
on your disk for that folder and compiles them into a working brain.

**What it reads** — the last **7 days**, or your **30 most recent sessions**,
whichever is *more*. So a heavy week is taken whole (98 sessions in 7 days →
all 98), and a quiet one still reaches back far enough to be useful.

**What you get** — three layers, not one summary:

```
.coding-brain/
├── STATE.md          ← the dashboard: active projects, conventions, open threads
├── topics/           ← one rolling note per project — what future sessions read
│   ├── my-api.md
│   └── web-client.md
└── sessions/         ← raw history: one digest per working session
    ├── 2026-08-05-auth-rewrite.md
    └── 2026-08-07-deploy-pipeline.md
```

`topics/` is the layer that matters day to day — compiled current truth per
project. `sessions/` is the audit trail behind it. `STATE.md` is what gets
injected at the start of your next session.

**How long** — one model call, 2-5 minutes, once per folder ever. After that
each agent finish costs a single incremental harvest.

It runs once per folder and is only marked done if it succeeds, so a failed
compile retries on your next agent finish rather than leaving you stuck with an
empty brain.

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
  "debounce_minutes": 30,   // minimum gap between saves in the same folder
  "workspace_root": null    // pin all saves to one folder (instead of per-agent)
}
```

Brain-side settings (model, corpus window) live in that folder's
`.coding-brain/config.json` — see [coding-brain](https://www.npmjs.com/package/coding-brain).

## How it works

- A `pane.agent_status_changed` hook fires when an agent reaches `done` or `idle`
- Queries `herdr api snapshot` to find that pane's working folder (not the hook's cwd)
- First time in a folder: runs `coding-brain init` there — the full compile above
- Every time after: runs `coding-brain harvest` — one incremental distill
- Brain stays fresh: old facts are replaced, not appended to
- No build, no daemon, no external config

**No cheap-model tier, deliberately.** A shallow digest is worse than no digest —
it writes confident-sounding wrong facts into `STATE.md`, and every later session
inherits them without re-checking. Harvests run on the best model the host offers.
Cost is controlled by *frequency* (the 30-minute debounce), not by degrading
quality.

## Why the brain stays current

Unlike transcript search tools that grow stale as they pile up, this brain
**recompiles itself per harvest**. Every session:

- Reads the transcript
- Compares against what the brain already knows
- Replaces outdated facts with new ones
- Adds decisions and gotchas only once
- Commits to git so you can see what changed

This is the same model OpenAI, Anthropic, and Google landed on for background
memory consolidation this year: bigger pile is not better memory. Cleaner pile is.

## Limits

**Read this before installing — it decides whether the plugin does anything for
you.**

The brain learns by reading the transcript files agents write to disk. Three of
Herdr's ~21 agent kinds write transcripts we can read:

| agent | transcripts | status |
|---|---|---|
| `claude` | `~/.claude/projects/` | ✅ supported |
| `cursor` | `~/.cursor/projects/` | ✅ supported |
| `codex`  | `~/.codex/sessions/`  | ✅ supported |
| `gemini`, `devin`, `cline`, `amp`, `grok`, `copilot`, `pi`, … | — | ❌ not yet |

If you only run agents from the bottom row, herdr-memory will scaffold a brain
directory, report success, and then **learn nothing** — there is no transcript
for it to read, for the first compile or for ongoing harvests. It currently fails
quietly rather than telling you. If that's your setup, wait for agent-agnostic
capture (reading pane output via `herdr agent read`), which is the planned fix.

If you run Claude Code, Cursor, or Codex under Herdr — including a mix of them —
they all feed one shared brain per folder, which is the whole point of putting
this at the Herdr layer instead of inside one vendor's tool.

Also worth knowing:

- **Backfill happens on first agent finish, not at install time.** Herdr 0.8.0
  has no post-install hook (`[[startup_commands]]` in a plugin manifest is
  silently ignored), so a plugin cannot run anything during `herdr plugin install`.
- **Each folder gets its own brain**, keyed by the pane's working directory.

## License

MIT.
