# Isolation: fresh context, and how it is defeated

Why a delegated worker's fresh context is useful, and the exact conditions under which it is not — so
swarm-agents claims only what holds.

## What holds (default, non-fork)

Each non-fork Claude Code subagent runs in a **fresh context window** that does **not** see the
parent's conversation history, system prompt, invoked skills, or already-read files. Only its final
message returns to the parent; the sole parent→child channel is the prompt string.
[code.claude.com/docs/en/sub-agents]

This is the real value of running a Corpus role as a subagent: a reviewer/explorer/auditor that starts
clean can't be primed by the parent's framing — it forms its own view from the artifacts. (It pairs
with refute-by-default review: an independent context is what makes "judge it fresh" meaningful.)

## What defeats it

- **Fork mode.** `CLAUDE_CODE_FORK_SUBAGENT=1` makes a subagent **inherit the full conversation, system
  prompt, tools, model, and history** — isolation is gone. swarm-agents assumes default (non-fork); if
  your environment forks subagents, the independence claim does not hold.
- **The prompt carries whatever the parent puts in it.** Isolation is about *inherited* context, not
  the task prompt — a parent can still paste its framing into the prompt. Independence is structural
  for *history*, conventional for *framing*.
- **Nested depth is fixed at five** (a depth-5 subagent loses the Agent tool) — not an isolation
  defeat, but a bound worth knowing for multi-hop delegation.

## What swarm-agents claims

Fresh-context independence **by default**, which is real and useful — with the fork-mode and
prompt-framing caveats above stated, not hidden. Combined with the delegation trace (`provenance.md`),
you get a worker whose inputs and context-filtering are *recorded* and whose history is *isolated* —
reviewability, not a security boundary (see `enforcement.md`).

Sources: see [sources.md](./sources.md).
