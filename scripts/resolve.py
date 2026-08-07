#!/usr/bin/env python3
"""Answers "which folder is this agent working in?" using herdr's own view.

Reads the plugin event on stdin and a `herdr api snapshot` as argv[1], and prints
one `key=value` line per fact for the shell to eval. herdr is the authority here:
the pane's foreground cwd is where the agent actually runs, which is not
necessarily the cwd of the hook process herdr spawned.

Prints nothing and exits 1 when the pane can't be resolved, so callers fall back.
"""
import json
import sys


def load(path):
    try:
        with open(path) as fh:
            return json.load(fh)
    except Exception:
        return {}


def main():
    try:
        event = json.load(sys.stdin)
    except Exception:
        event = {}
    snapshot = load(sys.argv[1]) if len(sys.argv) > 1 else {}

    # The event payload is wrapped differently depending on herdr version; the
    # fields we need are always somewhere in the tree, so search rather than
    # assume a shape.
    def dig(node, key):
        stack = [node]
        while stack:
            cur = stack.pop()
            if isinstance(cur, dict):
                if key in cur and not isinstance(cur[key], (dict, list)):
                    return cur[key]
                stack.extend(cur.values())
            elif isinstance(cur, list):
                stack.extend(cur)
        return None

    pane_id = dig(event, "pane_id")
    status = dig(event, "agent_status") or dig(event, "status") or ""
    agent = dig(event, "agent") or dig(event, "display_agent") or ""

    snap = snapshot.get("result", {}).get("snapshot", snapshot.get("snapshot", {}))
    panes = snap.get("panes", []) or []
    agents = snap.get("agents", []) or []

    cwd = None
    # An agent entry is the better source: it is the pane herdr attributed the
    # agent to, and it carries the agent's own session reference.
    for entry in agents:
        if entry.get("pane_id") == pane_id:
            cwd = entry.get("foreground_cwd") or entry.get("cwd")
            agent = entry.get("agent") or entry.get("display_agent") or agent
            session = entry.get("agent_session") or {}
            if session.get("kind") == "path" and session.get("value"):
                print("session_path=%s" % session["value"])
            break
    if not cwd:
        for pane in panes:
            if pane.get("pane_id") == pane_id:
                cwd = pane.get("foreground_cwd") or pane.get("cwd")
                break

    if not cwd:
        return 1

    print("workspace=%s" % cwd)
    print("status=%s" % status)
    print("agent=%s" % agent)
    print("pane_id=%s" % (pane_id or ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
