# Runners: Claude-Code-first, and how it ports (Codex + the universal layer)

suspec-agents authors **Claude Code definitions** as the single source, and **ports them** to a second
runner by generation: `suspec agents emit --codex` (suspec-cli) emits `.codex/agents/*.toml` from the
`agents/*.md` files, and the shared discipline ports through the open `AGENTS.md` format (ADR-0098).
Here is the honest reasoning — what travels and what does not.

## Why Claude Code first

Claude Code subagents are a mature, file-based authoring surface: Markdown + YAML frontmatter across
five discovery scopes, 16 documented frontmatter fields (only `name`+`description` required), real
fresh-context isolation, tool-scoping (`tools`/`disallowedTools` allowlists), `PreToolUse` blocking
hooks, and `SubagentStart`/`SubagentStop` hooks for the delegation trace. That is the full surface the
suspec-agents model needs, in one place. [code.claude.com/docs/en/sub-agents]

## The runner landscape (2026)

File-based agent definitions are now plural. A 2026 breadth survey (each fact checked against the
harness's own docs/source) groups them three ways:

- **The markdown + YAML-frontmatter camp** — the prevailing shape, the one suspec-agents already uses:
  a `name`/`description` header, the body as the system prompt. **Claude Code** (`.claude/agents/`),
  **Gemini CLI** (`.gemini/agents/*.md`, a `tools` array, inherit-all default
  [github.com/google-gemini/gemini-cli — docs/core/subagents.md]), **GitHub Copilot**
  (`.github/agents/*.md`, an _optional_ `tools` allowlist — default is all tools
  [docs.github.com/en/copilot/concepts/agents/cloud-agent/about-custom-agents]), **Cursor**
  (`.cursor/agents/`), and **Devin CLI** all share it.
- **The high-leverage cross-reads** — a Claude-Code-shaped file is _already partially portable_ with
  zero conversion: **Cursor reads `.claude/agents/`** as a "Claude compatibility" location
  [cursor.com/docs/subagents], **VS Code Copilot reads `.claude/agents/*.md`**
  [code.visualstudio.com/docs/agent-customization/custom-agents], and **Devin imports Claude Code's
  format**. The catch: only the _prompt/role_ travels — Claude's per-tool `tools:` allowlist has no
  equivalent (Cursor honors only a coarse `readonly`), and the hooks/provenance don't travel.
- **The carrier outliers** (the real porting cost — not markdown): **OpenAI Codex** is TOML
  (`.codex/agents/*.toml`: a `developer_instructions` string + an _optional_ per-agent `model`)
  [developers.openai.com/codex/subagents]; **Google Antigravity** defines managed agents
  _programmatically_ (an API/JSON object — fixed base model, no per-agent `model`; not a hand-authored
  `agent.json`/`agent.yaml` file) [ai.google.dev/gemini-api/docs/custom-agents]. The instruction text
  must be _projected_ into each.

## The universal discipline layer

The survey's strongest finding: a worker's _prose_ ports even where the per-agent file format does
not. **`AGENTS.md`** is an open cross-tool format read across the ecosystem (its site reports 60k+
projects and lists Codex, Gemini CLI, Cursor, Copilot, Aider, Windsurf, Amp, and more — an open
format, not a ratified standard [agents.md]); Antigravity's managed runtime auto-loads
`.agents/AGENTS.md`. And a **`name`+`description` `SKILL.md`** is shared by Claude Code _and_
Antigravity (`.agents/skills/<name>/SKILL.md`, identical shape
[ai.google.dev/gemini-api/docs/custom-agents]). So the discipline a suspec worker carries reaches the
guidance-only harnesses and Antigravity through `AGENTS.md` + `SKILL.md`, even though the per-agent
_definition_ does not.

## The portable layer (shipped — ADR-0098)

The portable layer is built, narrowed to what is honest. A Claude-Code-shaped definition's _role_ is
already portable into Cursor, VS Code Copilot, and Devin via their cross-reads — but **tool-scoping
enforcement and the provenance hook do not travel**: the prose discipline ports, structural enforcement
does not. Rather than a single per-agent file that lies about enforcement on
weaker runners, the design is **one source, generated adapters**:

- **Codex emitter — shipped.** `suspec agents emit --codex` (suspec-cli) generates `.codex/agents/*.toml`
  from the `agents/*.md` definitions (`developer_instructions` = the body). It is reuse, not a second
  hand-maintained copy — re-run after editing a definition. Every emitted file's header states that the
  `tools` allowlist and the hooks are Claude-Code-only and do not travel; a Codex adopter scopes tools
  in their own config.
- **The `.codex` no-diff guard — shipped (AC-005).** The generated TOMLs are committed (so Codex users
  get them on clone) and committed generated files drift — commit `ed424df` already had to
  "regenerate stale .codex toml". [`scripts/check-codex-sync.sh`](../scripts/check-codex-sync.sh)
  re-runs the real emitter (`suspec agents emit --codex --from agents --force`), then `git diff
  --exit-code -- .codex/` and **fails when the committed `.codex/` drifted** — also catching an _orphan_
  TOML (a deleted agent whose generated file lingers, since emit only writes, never deletes). It is a
  check, not an executor (ADR-0077): it edits nothing. [`.github/workflows/codex-sync.yml`](../.github/workflows/codex-sync.yml)
  runs it in CI on any change to `agents/**` or `.codex/**`; locally, `bash scripts/check-codex-sync.sh`.
- **The universal `AGENTS.md` discipline — formalized.** The shared discipline (evidence over
  assertion, reconcile-only/no-verdict, the trace as reviewability, honesty levels) is single-sourced
  in this repo's `AGENTS.md`, the open cross-tool format read by Codex, Cursor, Copilot, Gemini CLI,
  and Aider. The per-agent files are its Claude-Code specialization — no hand-duplicated `SKILL.md`.
- **Managed-runner support.** Runners configured through managed APIs, rather than portable definition
  files, use the universal `AGENTS.md` discipline. A file emitter ships only when the runner exposes a
  file-based adapter target.

What ships is the emitter + the universal layer; the **value proof** requires measured use by multiple
real external runner teams (see [The gate this bears on](#the-gate-this-bears-on)).

## Per-agent model — an optional adopter knob (not shipped)

These definitions pin **no** `model:` — they inherit the session model, so a definition never rots when
a new model ships (ADR-0092). But Claude Code subagents _support_ a `model:` frontmatter field, and the
cost/quality spread is real (a Haiku scout vs a capable judge). Since you copy and adapt these files,
add it yourself where cost-tiering pays off — e.g. `model: haiku` on a cheap read-only scout (the
built-in Explore agent, or `suspec-reviewer` in its proof-first mode), a stronger model on
`suspec-reviewer` for a full review / `suspec-challenger` (judgement). We ship no defaults on purpose;
the knob is yours.

**Per-lens cost tiers (opt-in, ADR-0124).** For a multi-lens Revolver review, map roles to abstract tiers
(`cheap` / `mid` / `strong`) and let the runner resolve each alias — route the blind lens reviewers to a
cheaper tier and the reconciling lead plus high-risk lenses (security, architecture) to a stronger one; a
mixed-tier panel should also help decorrelate the reviewers (ADR-0124). Two rules keep it honest: model **size is not a quality
proxy** — tier is non-monotonic for review, so the axis that transfers is the **capability profile**
(reasoning / calibration / signal-to-noise), not the size ladder; and a cheap tier is a hypothesis until
**validated on real changes matched to the diff-size regime** — synthetic-benchmark wins do not transfer.
Still no defaults: the map and its alias table are yours.

## The gate this bears on

suspec-agents was held on "≥2 runners _demonstrating value_." The runners _exist_ with compatible
formats, but v1 demonstrates value on **Claude Code only** — so that gate is **not** met by founding;
the founding is a conscious override conditioned on the measurement wave (ADR-0092). Portability is the
path to actually clearing it later.

Sources: see [sources.md](./sources.md).
