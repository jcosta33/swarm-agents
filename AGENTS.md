# AGENTS.md — corpus-agents

This repo is the optional **agent-definition** catalog for the Corpus framework: self-contained,
Claude-Code-first worker definitions for Corpus roles, one file per agent under `agents/`, the
delegation-provenance + read-only-guard hooks under `hooks/`, and the evidence behind their design
under `docs/`. It is a derived-content repo — it carries no Corpus workspace install; the work of
changing it is planned and reviewed in the family workspace (the sibling `corpus-works` repo). The
founding decision is [ADR-0092](https://github.com/jcosta33/corpus/blob/main/docs/adrs/0092-corpus-agents-member.md)
(the `ADR-NNNN` citations here are decision records in the
[corpus repo](https://github.com/jcosta33/corpus/tree/main/docs/adrs)).

## What this is NOT

Not an orchestrator, not a runtime, not a multi-agent loop. A catalog of definitions + two hooks are
**records and tripwires, never an executor** (ADR-0077 / ADR-0088). The only CLI launcher is
`corpus run --agent` (optional, in [corpus-cli](https://github.com/jcosta33/corpus-cli)); the standalone
path these definitions support — in-session subagents spawned by your own runner's Agent tool — needs
no CLI. The absence of orchestration stays observable.

## Portability — the universal layer (ADR-0098)

These definitions are **Claude-Code-first**, but the _prose discipline_ is portable, so the catalog
reaches other runners without a second hand-maintained copy:

- **The definitions are the single source.** `corpus agents emit --codex`
  ([corpus-cli](https://github.com/jcosta33/corpus-cli)) projects each `agents/*.md` into an OpenAI Codex
  `.codex/agents/<name>.toml` (`developer_instructions` = the body). It **generates**, never duplicates
  — re-run it after editing a definition; do not hand-edit the TOML.
- **`AGENTS.md` is the open cross-tool format.** This file's discipline — evidence over assertion
  (ADR-0056), reconcile-only / no self-issued verdict (ADR-0077 D8), the delegation trace as
  reviewability not a guarantee (ADR-0088), honesty levels (ADR-0063) — is the layer that ports to any
  runner that reads an `AGENTS.md` (Codex, Cursor, Copilot, Gemini CLI, Aider). It is the universal
  contract; the per-worker files are the Claude-Code specialization of it.
- **What does NOT travel (honest scope, ADR-0098).** The `tools` allowlist and the `hooks/`
  (`readonly-guard`, the delegation-provenance trace) are **Claude-Code structural mechanisms** — they
  do not port. A Codex (or other) adopter gets the prose discipline and must grant/deny tools in their
  own runner config; the read-only guarantee is honor-system there. Every emitted file says so in its
  header. Enforcement is Claude-Code-only; the discipline is everywhere.
- **Antigravity: considered, dropped (ADR-0098).** Google Antigravity's managed agents are configured
  programmatically, not via a portable definition file, so there is no honest file-emitter target — the
  universal `AGENTS.md` discipline (this file's prose; no separate `SKILL.md` is generated) is the only
  thing that reaches it, and that needs no adapter. No Antigravity emitter ships.
- **The do-not-found gate / measurement wave is the honest exception (ADR-0092).** Demonstrating value
  across ≥2 _real external_ runner teams is un-fabricatable here; it stays a standing owner-run
  activity, not a build item.

## Editing rules

- **One agent per file:** `agents/<name>.md` — Claude Code subagent format (YAML frontmatter + a body
  that is the system prompt). Only `name` + `description` are required.
- **Description is the trigger:** directive — open with the verb of the work, say when to ALWAYS apply,
  name what the worker refuses, end with a `Skip …` clause.
- **No pinned `model`:** agents inherit the session model so a definition does not rot per release.
- **Tool-scoping by tier:** read-only (Tier 1) agents set a `tools` allowlist that **excludes
  Edit/Write**; the ones that keep `Bash` name the `readonly-guard` hook. Authoring (Tier 2) agents
  grant Edit/Write and **state in the body that scoping is honor-system, not enforcement**.
- **Self-contained + canon-grounded:** the body carries its own discipline, grounded in the durable
  canon ADRs (ADR-0056 self-review, ADR-0077 reconcile-only/no-verdict, ADR-0088 trace). It must read
  correctly with nothing else installed. A persona/guide is an OPTIONAL one-line "pairs with … if you
  use it" see-also — never a dependency (personas live in `corpus-skills`; core/authoring guides in the
  starter kit). Nothing here depends on a persona.
- **Honesty (ADR-0063):** never label anything "enforced". Read-only scoping is **toolable/partial**
  (defeasible — see `docs/enforcement.md`); a trace buys reviewability/attribution, not a guarantee.
- **No verdict (ADR-0077 D8):** a worker drafts and reports; it never records Pass/Fail or closes a task.
- Markdown + the two POSIX-sh hook scripts only — no other executables, no network calls.
- The catalog tables in `README.md` gain/lose a row with every agent added/removed.

## Commands

| Slot | Command | Resolves                                                                                                    |
| ---- | ------- | ----------------------------------------------------------------------------------------------------------- |
| —    | (none)  | markdown + shell-hook repo; content is checked by review (the corpus-works workspace cuts and reviews changes) |
