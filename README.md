# swarm-agents

> Optional, Claude-Code-first **worker definitions** for the [Corpus](https://github.com/jcosta33/swarm)
> roles — independent review, exploration, evidence-checking, and bounded authoring — each a
> self-contained Claude Code subagent you copy into a repo. Records and tripwires, never an
> orchestrator.

Each agent runs a Corpus role in a **fresh, isolated context**, with its tools scoped to the work, and
(with the hook) leaves a **delegation trace** for review — partially structured and version-dependent
(see [hooks/README.md](./hooks/README.md)). The discipline is baked into each definition; you copy the
one you need. Nothing here runs a model loop or owns the **verdict** — the accept/reject decision on a
task, which a human still makes (ADR-0077; the review vocabulary is defined in the
[Corpus glossary](https://github.com/jcosta33/swarm/blob/main/docs/reference/glossary.md)).

## Install

Claude Code discovers agents from a repo's `.claude/agents/` directory. **Copy the one you want:**

```bash
# ensure the target dirs exist (a fresh repo has neither)
mkdir -p <your-repo>/.claude/agents <your-repo>/.claude/hooks

# one agent into the current repo
cp agents/swarm-reviewer.md <your-repo>/.claude/agents/

# the delegation-provenance hook (optional) + wire it in .claude/settings.json (see hooks/README.md)
cp hooks/delegations.sh <your-repo>/.claude/hooks/ && chmod +x <your-repo>/.claude/hooks/delegations.sh
# the read-only guard for the Bash-holding workers
cp hooks/readonly-guard.sh <your-repo>/.claude/hooks/ && chmod +x <your-repo>/.claude/hooks/readonly-guard.sh
```

Copy-based by design: these are Claude Code **agents** (`.claude/agents/`), not Agent-Skills
(`.agents/skills/`), so the `npx skills` CLI does not install them. Use it for the
[swarm-skills](https://github.com/jcosta33/swarm-skills) catalog; copy the agents here.

## The AGENTS.md contract

An agent body names abstract command slots (`cmdTest`, `cmdLint`, …) where it must re-run a project's
checks; the consuming repo's `AGENTS.md` supplies the concrete commands. An empty slot means **ask**.
That split keeps an agent portable across repos.

A consuming repo's `AGENTS.md` fills the slots — for example:

| Slot | Command |
|---|---|
| cmdTest | `npm test` |
| cmdLint | `npm run lint` |

(This repo's own [AGENTS.md](./AGENTS.md) Commands table reads `(none)` — it is markdown-only, with no
test/lint of its own to run.)

## Where to start

You need none of these to run Corpus — the [starter kit](https://github.com/jcosta33/swarm-starter-kit)
ships the loop. Add an agent when delegating that role to an isolated, scoped subagent earns its keep:

1. **`swarm-reviewer`** — the first one most want: an independent, read-only reviewer for a finished
   task or PR that re-runs the Verify checks and drafts a packet without issuing the verdict.
2. **A read-only helper** — `swarm-explorer` to map a codebase, `swarm-evidence-checker` to re-run and
   paste Verify output.
3. **A bounded-authoring worker** — `swarm-spec-author` / `swarm-researcher` / `swarm-auditor` /
   `swarm-documentarian` — when you want a disciplined, isolated, traced first draft of one artifact.

## Why not just the built-in reviewer + a CLAUDE.md?

You can get far with your runner's built-in agents and a `CLAUDE.md`. These add three things those do
not: a **fresh, isolated context per role** — the subagent is never primed by your main thread's
framing ([`docs/isolation.md`](./docs/isolation.md)); a hard refusal to **self-issue a verdict** — the
reviewer/checker draft and a human decides (ADR-0077); and, with the hook, a **reviewable delegation
trace** the built-ins don't emit. When none of those matter, the built-ins are the lighter choice —
reach for these when the isolation, the no-self-verdict rule, or the trace earns its keep.

## Catalog

### Tier 1 — read-only workers

Their `tools` allowlist excludes Edit/Write; the ones that keep `Bash` (to re-run Verify) pair with
the `readonly-guard` hook. **Scoping is toolable/partial — it narrows the surface, it is not a
guarantee** (see [The science](#the-science)).

| Agent | Use it when |
|---|---|
| [`swarm-reviewer`](./agents/swarm-reviewer.md) | Independently reviewing a finished task/PR — re-run Verify, read the diff, draft the packet, **no verdict** |
| [`swarm-explorer`](./agents/swarm-explorer.md) | Orienting in a codebase read-only — locate/trace how something works and report (no edits, no Bash) |
| [`swarm-evidence-checker`](./agents/swarm-evidence-checker.md) | Re-running a task's Verify items and pasting verbatim output; flagging claims without evidence |
| [`swarm-challenger`](./agents/swarm-challenger.md) | Pressure-testing a proposal/spec/plan before it is built — assumptions, the steelmanned alternative, external evidence |

_Of these, only `swarm-reviewer` and `swarm-evidence-checker` hold `Bash` (so the `readonly-guard`
applies to them); `swarm-explorer` and `swarm-challenger` have no Bash and need no guard._

### Tier 2 — bounded-authoring workers

These grant Edit/Write to draft one artifact. **Their value is the baked-in discipline + fresh-context
isolation + the delegation trace — NOT enforcement** (a granted Write is not path-locked; the body
says so). Each refuses to self-issue a verdict.

| Agent | Use it when |
|---|---|
| [`swarm-spec-author`](./agents/swarm-spec-author.md) | Drafting a spec from an intake note — verifiable requirements, no smuggled implementation |
| [`swarm-researcher`](./agents/swarm-researcher.md) | Investigating one question against primary sources → a research note, committing to no decision |
| [`swarm-auditor`](./agents/swarm-auditor.md) | Auditing a code area — present state, file:line, severity by impact, observation not prescription |
| [`swarm-documentarian`](./agents/swarm-documentarian.md) | Drafting human-facing docs — one Diátaxis frame, every example run as written |

_`swarm-auditor` and `swarm-documentarian` also hold `Bash` (to run read-only inspections / run doc
examples). The `readonly-guard` is a global `Bash` matcher, so it covers them too where you want their
shell use kept read-only._

## The science

[`docs/`](./docs/) documents the evidence behind the design, and — bluntly — the limits:
- [`enforcement.md`](./docs/enforcement.md) — what tool-scoping + hooks actually guarantee
  (toolable/partial) vs. what is honor-system, with the bypass-bug cluster cited.
- [`isolation.md`](./docs/isolation.md) — fresh-context isolation and how it is defeated (fork mode,
  parent permission modes).
- [`provenance.md`](./docs/provenance.md) — the ADR-0088 delegation trace, aligned with HDP + OpenTelemetry.
- [`runners.md`](./docs/runners.md) — Claude-Code-first, and how it ports: `swarm agents emit --codex` generates the Codex form from the single-source defs; the `AGENTS.md` discipline is the universal layer (enforcement stays Claude-Code-only).
- [`sources.md`](./docs/sources.md) — the bibliography.

## Security

Read an agent before installing it — a definition is instructions your agent will follow. Everything
here is plain markdown plus two short POSIX-sh hooks; the hooks make no network calls and run no other
executables (the `swarm-challenger` and `swarm-researcher` agents do request `WebSearch`/`WebFetch` for
external grounding — read those two before installing). The read-only guarantees are **partial** (see
`docs/enforcement.md`): a `tools` allowlist + a tripwire hook raise the bar but do not sandbox a shell.
The delegation trace is written in plaintext under `.swarm/work/` (gitignored) and can contain prompt
and model-output content — treat it as sensitive at rest. Pin to a commit for a stable install.

## Relationship to the Corpus framework

These agents assume nothing about Corpus beyond a repo with an `AGENTS.md` — each stands alone. They are
runner-specific (Claude Code) projections of the Corpus roles; the framework and its docs live at
[jcosta33/swarm](https://github.com/jcosta33/swarm), the copy-whole workspace at
[jcosta33/swarm-starter-kit](https://github.com/jcosta33/swarm-starter-kit), the agent-neutral
disciplines at [jcosta33/swarm-skills](https://github.com/jcosta33/swarm-skills). This catalog is
curated: agent content is edited here; changes are planned and reviewed in the Corpus project's
workspace. Founding decision: [ADR-0092](https://github.com/jcosta33/swarm/blob/main/docs/adrs/0092-swarm-agents-member.md).
The `ADR-NNNN` citations throughout these docs are decision records in the
[swarm repo's `docs/adrs/`](https://github.com/jcosta33/swarm/tree/main/docs/adrs) — the gloss beside
each here is self-sufficient.

## License

MIT — see [LICENSE](./LICENSE). Copy these files into your repo freely.
