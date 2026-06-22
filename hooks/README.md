# Hooks

Two opt-in Claude Code hooks. Copy the one you want into your repo's `.claude/hooks/`
(`chmod +x` it) and wire it in `.claude/settings.json`. Both are **records/tripwires, never an
executor or a guarantee** — they raise reviewability and the bar, nothing more.

## `delegations.sh` — delegation-provenance (ADR-0088 producer 2)

`swarm run --agent` records a provenance block for the workers **it** launches (producer 1). But
**in-session subagents** — the ones the main agent spawns through Claude Code's own Agent tool —
never touch the CLI. This hook is producer 2: one NDJSON trace line per subagent event in
`.swarm/work/delegations.ndjson`, so delegation is reviewable too. A record, never a verdict
(ADR-0077 D8); always exits 0, so provenance never blocks the agent.

```json
{
  "hooks": {
    "SubagentStart": [{ "hooks": [{ "type": "command", "command": ".claude/hooks/delegations.sh SubagentStart" }] }],
    "SubagentStop":  [{ "hooks": [{ "type": "command", "command": ".claude/hooks/delegations.sh SubagentStop" }] }]
  }
}
```

It records the ADR-0088 fields (`worker`, `reason`, `inputs`, `filtered`, `tools`, `could_edit`,
`evidence`, + `ts`/`event`/`raw`), mapped **best-effort** from the Claude Code payload — adjust the
`jq` to your version's actual SubagentStart/Stop field names. (`SubagentStart` fires but **cannot
block**; it is for the trace, not enforcement.)

Verified end-to-end against **Claude Code v2.1.173** (Jun 2026): `worker` resolves via `.agent_type`
and `evidence` via `.last_assistant_message` (on `SubagentStop`); `reason`/`inputs`/`tools`/`could_edit`
are not in that version's payload, so they fall to `null` — the whole event is kept under `raw`, and
`raw.transcript_path` lets a reviewer recover the rest. Re-check the field names on your version.

## `readonly-guard.sh` — a write-ish-Bash tripwire (PreToolUse) for Bash-holding agents

The read-only workers drop Edit/Write but keep Bash (to re-run Verify), and a shell can still write.
This `PreToolUse` hook `exit 2`-blocks the obvious source-mutating / destructive / publish idioms —
`git commit`/`push`/`add`/`reset`/`restore`/`stash`/`rm`/`checkout`/`clean`/`switch` (matched by
subcommand, so `git -C <dir> commit` and `git --no-pager push` are caught too; a read-only
`--dry-run`/`--help`, or `git clean -n`/`add -n`, is allowed), `sed -i`,
`rm`/`rmdir`/`mv`/`chmod`/`chown`, and `*publish` — anchored to each segment's leading command word
(after peeling `sudo`/`xargs` wrappers, a leading subshell `(`/`{`, and `VAR=val` prefixes). It is a
global `Bash` matcher, so it fires for **any** agent granted Bash: the Tier-1 reviewer/evidence-checker
and — where you want their shell use kept read-only — the Tier-2 `swarm-auditor`/`swarm-documentarian`.

```json
{
  "hooks": {
    "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": ".claude/hooks/readonly-guard.sh" }] }]
  }
}
```

## Honest scope (read this)

These are **toolable/partial** (ADR-0063), not "enforced":
- The guard is a **tripwire, not a wall** — a write where the leading word looks innocent still escapes
  (`find . -exec rm {} \;`, a write inside `python`/`node`, a heredoc to an editor, base64, or `xargs`
  of an unlisted writer; a quoted `git -c` value with a space — `git -c user.name='Jo Co' commit` —
  or an inline alias — `git -c alias.x=commit x`), as do **writers not on the denylist**
  (`git branch -D`, `cp`, `mkdir`, `touch`, `dd`); output redirections (`>`/`tee`) are deliberately
  **not** matched (too
  false-positive-prone against legit build/test writes) — tune the denylist to your repo.
- Both hooks are **defeasible**: a parent in `bypassPermissions`/`acceptEdits`/`auto`, or a
  plugin-loaded subagent, bypasses hooks entirely (claude-code#25000 / #43142 / #54898).
- Pair the guard with a `tools` allowlist that excludes Edit/Write (the agent definitions do this).

Verify the hook event names + `settings.json` shape against your Claude Code version — the
lifecycle-hook surface evolves; these are v0 recipes.
