# Sources

The evidence behind corpus-agents' design and its honest-scope claims. Verified in the deep-research
refresh of 2026-06-21 (corpus-works `specs/corpus-agents/research-shipping.md`, 3-vote adversarial
verification); re-check primary sources before relying on a version-specific detail.

## Claude Code subagents (the authoring + enforcement surface)

- Claude Code — Subagents (frontmatter fields, scopes, isolation, `tools`/`disallowedTools`,
  `permissionMode`, `PreToolUse` blocking, `SubagentStart`/`SubagentStop`, built-in agents):
  https://code.claude.com/docs/en/sub-agents

## The bypass / honest-limit evidence

- claude-code#25000 — subagent Bash tool-scoping bypass (bare-name deny rules dropped before
  evaluation): https://github.com/anthropics/claude-code/issues/25000
- claude-code#43142, #54898 — related open subagent permission/bypass reports:
  https://github.com/anthropics/claude-code/issues/43142 ·
  https://github.com/anthropics/claude-code/issues/54898

## The runner landscape (founding-gate + portability-survey evidence)

- GitHub Copilot — custom agents (`.github/agents/*.md`, optional `tools`, default all):
  https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-custom-agents
- VS Code Copilot — also reads `.claude/agents/*.md` (Claude format):
  https://code.visualstudio.com/docs/agent-customization/custom-agents
- Gemini CLI — subagents (`.gemini/agents/*.md`, `tools` array, inherit-all default): https://github.com/google-gemini/gemini-cli/blob/main/docs/core/subagents.md
- Cursor — subagents (reads `.claude/agents/` as "Claude compatibility"; coarse `readonly`): https://cursor.com/docs/subagents
- OpenAI Codex — subagents (TOML `.codex/agents/*.toml`; `developer_instructions` + optional `model`): https://developers.openai.com/codex/subagents
- Google Antigravity — managed agents (created programmatically; fixed base model; auto-loads `.agents/AGENTS.md` + a `name`+`description` `SKILL.md`): https://ai.google.dev/gemini-api/docs/custom-agents
- AGENTS.md — the open cross-tool guidance format (site reports 60k+ projects): https://agents.md

## Delegation-provenance prior art (vocab alignment)

- HDP — Human Delegation Provenance: https://arxiv.org/abs/2604.04522 ·
  https://datatracker.ietf.org/doc/draft-helixar-hdp-agentic-delegation/
- OpenTelemetry GenAI agent spans + the open delegation-attributes proposal:
  https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-agent-spans/ ·
  https://github.com/open-telemetry/semantic-conventions-genai/issues/35

## Corpus canon (the contract)

- ADR-0088 (delegation-provenance contract), ADR-0077 (reconcile-only / a record never a verdict),
  ADR-0056 (adversarial self-review), ADR-0063 (honesty framework / levels), ADR-0092 (founding
  corpus-agents) — the `ADR-NNNN` citations in these docs live at
  [github.com/jcosta33/corpus/tree/main/docs/adrs](https://github.com/jcosta33/corpus/tree/main/docs/adrs).

## Paired guides (optional see-alsos named in the agent bodies)

- The authoring guides (`write-spec`, `write-audit`, `write-research`, `write-inventory`,
  `review-output`) ship in the [starter kit](https://github.com/jcosta33/corpus-starter-kit); the
  `write-documentation` guide and the `empirical-proof` discipline ship in
  [corpus-skills](https://github.com/jcosta33/corpus-skills). None is a dependency — each agent body
  stands alone.
