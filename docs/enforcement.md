# Enforcement: what is real, what is honor-system

The honest scope of swarm-agents' guarantees. Per the Corpus honesty framework (ADR-0063), a rule is
**toolable/partial** when a tool narrows the surface, and **enforced** only when a tool actually
guarantees it. **Nothing in swarm-agents is "enforced."**

## What is structurally real (toolable/partial)

For the *static* path, Claude Code does narrow what a subagent can reach:
- **`tools` is an allowlist** — a tool absent from the list cannot be called. So a read-only worker
  whose list excludes Edit and Write cannot call Edit or Write. (Caveat: **omitting `tools` inherits
  ALL tools** — scoping is opt-in; our read-only agents set the list explicitly.)
- **`disallowedTools`** removes tools (including `mcp__*` to strip MCP).
- **`PreToolUse` hooks that `exit 2`** block an operation before it runs — the basis of
  `readonly-guard.sh`.
[code.claude.com/docs/en/sub-agents]

## What is NOT a guarantee (honor-system / defeasible)

These are the limits, stated plainly — design around them, don't assume them away:

- **A granted `Bash` can still write.** The read-only workers keep `Bash` to re-run Verify; a shell
  can `sed -i`, `git commit`, write files. `readonly-guard.sh` is a **tripwire** that blocks the
  obvious idioms — a write inside `python`/`node`, a heredoc, or base64 evades it; a quoted `git -c`
  value with a space (`git -c user.name='Jo Co' commit`) or an inline alias (`git -c alias.x=commit x`)
  also slips past the subcommand match; and it deliberately doesn't match output redirections
  (false-positive-prone). It raises the bar; it is not a sandbox.
- **Tier-2 authoring agents hold Edit/Write** to draft one artifact — nothing path-locks them. Their
  value is the discipline + isolation + the trace, **not** enforcement.
- **Parent permission context wins.** If the parent runs `bypassPermissions`/`acceptEdits`, that takes
  precedence and the child's `permissionMode` cannot override it; in `auto` the child's mode is ignored.
- **Plugin-loaded subagents ignore `hooks`, `mcpServers`, and `permissionMode`** (by design).
- **Fork mode drops isolation** (`CLAUDE_CODE_FORK_SUBAGENT=1` — see `isolation.md`).
- **A reproducible bypass exists:** with a bare-name `Bash` deny rule, a Task-launched subagent ran 22+
  bash commands with no approval — bare-name deny rules are dropped before evaluation
  ([claude-code#25000]). A wider open-bug cluster: [#43142], [#54898]. `SubagentStart` fires but
  **cannot block**.

## The honest conclusion

A `tools` allowlist + a tripwire hook + a delegation trace buy **reviewability and attribution, and a
narrower default surface** — they do **not** guarantee behavior. Use swarm-agents to make delegation
*visible and disciplined*, not to *sandbox* an untrusted agent. For a real boundary, run the agent in
an OS/container sandbox; these definitions are not that.

Sources: see [sources.md](./sources.md).
