#!/bin/sh
# Read-only guard (PreToolUse, Bash) — swarm-agents.
#
# The Tier-1 read-only workers (swarm-reviewer, swarm-evidence-checker) drop Edit/Write from their
# tools allowlist but KEEP Bash — because they must re-run a task's Verify commands. A shell can still
# write, so this hook is a TRIPWIRE, not a wall: it `exit 2`-blocks the obvious source-mutating /
# destructive / publish idioms a reviewer should never reach for, raising the bar against
# edit-via-shell. It is NOT a guarantee (ADR-0063 — "toolable/partial", never "enforced"):
#   - it matches the LEADING command word of each segment, so a dangerous token that is only an
#     ARGUMENT (`grep -rn chmod src/`, `rg "rm -rf" .`, `echo "how to rm files"`) is NOT blocked —
#     but a write hidden past a flag (`find . -exec rm {} \;`), inside python/node/perl, base64, or
#     an editor heredoc still escapes;
#   - it does not block output redirections (`>`/`tee`) — too false-positive-prone against legit
#     build/test writes — so those remain a known gap; tune the denylist to your repo;
#   - a parent in bypassPermissions/acceptEdits/auto, or a plugin-loaded subagent, bypasses hooks
#     entirely (claude-code#25000 / #43142). Pair this with a tools allowlist that excludes Edit/Write.
#
# Wire it as a Bash PreToolUse hook in `.claude/settings.json` (see README.md). Exit 0 = allow,
# exit 2 = block before the command runs.
set -eu

payload="$(cat 2>/dev/null || true)"
if command -v jq >/dev/null 2>&1 && printf '%s' "$payload" | jq -e . >/dev/null 2>&1; then
    cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // .command // empty' 2>/dev/null || true)"
else
    cmd="$payload"
fi
[ -z "$cmd" ] && exit 0   # nothing to inspect -> allow

# Unambiguous source-mutation / destructive / publish idioms. Matching is anchored to the LEADING
# command word of each segment: the command is split on shell separators (; | & && || and newlines)
# and common wrappers (sudo/xargs/time/env/nice/nohup/command) are peeled, so a dangerous token that
# is only an argument (`grep -rn chmod src/`) is not a false positive. Builds, tests, and redirections
# are deliberately NOT matched (commonly legitimate Verify steps) — that gap is documented above.
deny=
oldifs="$IFS"
IFS='
'
for seg in $(printf '%s' "$cmd" | tr ';|&\n' '\n\n\n\n'); do
    seg="${seg#"${seg%%[![:space:]]*}"}"             # strip leading whitespace
    while :; do                                       # peel a leading wrapper word, then re-strip
        case "$seg" in
            "sudo "*|"xargs "*|"time "*|"env "*|"nice "*|"nohup "*|"command "*)
                seg="${seg#* }"
                seg="${seg#"${seg%%[![:space:]]*}"}" ;;
            *) break ;;
        esac
    done
    case "$seg" in
        "git commit"*|"git push"*|"git add "*|"git reset"*|"git restore"*|"git stash"*|"git rm "*|\
        "sed -i"*|"sed --in-place"*|\
        "rm "*|rm|"rmdir "*|rmdir|"mv "*|"chmod "*|"chown "*|\
        "npm publish"*|"yarn publish"*|"pnpm publish"*)
            deny="$seg" ; break ;;
    esac
done
IFS="$oldifs"

if [ -n "$deny" ]; then
    printf 'read-only guard: blocked a write-ish/destructive Bash command:\n  %s\nswarm-agents read-only workers re-run Verify and report — they do not mutate source. Make the change a separate task. (toolable/partial — a tripwire, not a guarantee.)\n' "$cmd" >&2
    exit 2
fi

exit 0
