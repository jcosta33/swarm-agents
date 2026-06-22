# Runners: why Claude-Code-first, and why not portable (yet)

swarm-agents ships Claude Code definitions only. Here is the honest reasoning — and what would change it.

## Why Claude Code first

Claude Code subagents are a mature, file-based authoring surface: Markdown + YAML frontmatter across
five discovery scopes, 16 documented frontmatter fields (only `name`+`description` required), real
fresh-context isolation, tool-scoping (`tools`/`disallowedTools` allowlists), `PreToolUse` blocking
hooks, and `SubagentStart`/`SubagentStop` hooks for the delegation trace. That is the full surface the
swarm-agents model needs, in one place. [code.claude.com/docs/en/sub-agents]

## The runner landscape (2026)

File-based agent definitions are now plural — which is why founding this member is justified on the
ecosystem axis:
- **GitHub Copilot** — custom agents as Markdown+YAML in `.github/agents/*.md`, tool allowlist + MCP
  scoping. [docs.github.com/en/copilot/reference/custom-agents-configuration]
- **Gemini CLI** — file-based subagents, a `tools` frontmatter array, inherit-all default.
  [github.com/google-gemini/gemini-cli — docs/core/subagents.md]
- **Cursor** — reads `.claude/agents/` directly as a compatibility location, so a Claude Code
  definition's *prompt/role* is discovered as-is (tool-scoping is only a coarse `readonly` boolean; no
  provenance). [cursor.com/docs/context/subagents]

## Why no portable file (yet)

The field sets **diverge** (Gemini lacks `disallowedTools`/`permissionMode`/`hooks`; Copilot is
allowlist-only; Cursor has only `readonly`), and crucially **tool-scoping enforcement and the
provenance hook do not travel**. So a single "AGENTS.md for subagents" would either lie about
enforcement on the weaker runners or collapse to the lowest common denominator. The honest scope is:
**Claude-Code-first definitions now; documented per-runner mappings later, on demonstrated demand.**
(Cursor users already get the role for free via `.claude/agents/` discovery — minus enforcement.)

## Per-agent model — an optional adopter knob (not shipped)

These definitions pin **no** `model:` — they inherit the session model, so a definition never rots when
a new model ships (ADR-0092). But Claude Code subagents *support* a `model:` frontmatter field, and the
cost/quality spread is real (a Haiku scout vs a capable judge). Since you copy and adapt these files,
add it yourself where cost-tiering pays off — e.g. `model: haiku` on `swarm-explorer` /
`swarm-evidence-checker` (cheap read-only scouts), a stronger model on `swarm-reviewer` /
`swarm-challenger` (judgement). We ship no defaults on purpose; the knob is yours.

## The gate this bears on

swarm-agents was held on "≥2 runners *demonstrating value*." The runners *exist* with compatible
formats, but v1 demonstrates value on **Claude Code only** — so that gate is **not** met by founding;
the founding is a conscious override conditioned on the measurement wave (ADR-0092). Portability is the
path to actually clearing it later.

Sources: see [sources.md](./sources.md).
