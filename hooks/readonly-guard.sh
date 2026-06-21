#!/bin/sh
# Read-only guard (PreToolUse, Bash) — swarm-agents.
#
# The Tier-1 read-only workers (swarm-reviewer, swarm-evidence-checker) drop Edit/Write from their
# tools allowlist but KEEP Bash — because they must re-run a task's Verify commands. A shell can still
# write, so this hook is a TRIPWIRE, not a wall: it `exit 2`-blocks the obvious source-mutating /
# destructive / publish idioms a reviewer should never reach for, raising the bar against
# edit-via-shell. (It also covers the Bash-holding Tier-2 authoring agents — swarm-auditor,
# swarm-documentarian — when you want their shell use kept read-only; the matcher is a global Bash
# PreToolUse hook, so it fires for ANY agent granted Bash.) It is NOT a guarantee (ADR-0063 —
# "toolable/partial", never "enforced"):
#   - it matches each segment's LEADING command word (after folding subshell/brace delimiters `(){}`
#     to spaces and peeling `sudo`/`xargs`/… wrappers + `VAR=val` assignments) and, for git, the SUBCOMMAND
#     behind any global flags (so `git -C <dir> commit`, `git -c k=v commit`, `git --no-pager push`
#     are caught) — so a dangerous token that is only an argument (`grep -rn chmod src/`,
#     `rg "rm -rf" .`, `echo "how to rm files"`) is NOT a false positive;
#   - a write whose leading word looks innocent still escapes: `find . -exec rm {} \;`, a write inside
#     python/node/perl, an editor heredoc, base64, or `xargs <some-unlisted-writer>`;
#   - it does not block output redirections (`>`/`tee`) — too false-positive-prone against legit
#     build/test writes — so those remain a known gap; tune the denylist to your repo;
#   - a parent in bypassPermissions/acceptEdits/auto, or a plugin-loaded subagent, bypasses hooks
#     entirely (claude-code#25000 / #43142 / #54898). Pair this with a tools allowlist excluding Edit/Write.
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

# Normalize whitespace (tab, CR, FF, VT) to spaces so a tab between the command word and its argument
# (`rm<TAB>-rf`, `git<TAB>commit`) can't slip the space-anchored matcher; fold subshell/brace delimiters
# `(){}` to spaces too, so `(git commit)` / `{ rm x; }` expose their real command word the same way.
cmd="$(printf '%s' "$cmd" | tr '\t\r\f\v' '    ' | tr '(){}' '    ')"

# Unambiguous source-mutation / destructive / publish idioms, anchored to each segment's LEADING
# command word. The command is split on shell separators (; | & && || and newlines); per segment we
# peel leading wrappers / subshell-or-brace openers / VAR=val assignments, then test the leading word
# (and, for git, the subcommand behind global flags). Builds, tests, and redirections are deliberately
# NOT matched (commonly legitimate Verify steps) — that gap is documented above.
deny=
oldifs="$IFS"
IFS='
'
for seg in $(printf '%s' "$cmd" | tr ';|&\n' '\n\n\n\n'); do
    seg="${seg#"${seg%%[![:space:]]*}"}"             # strip leading whitespace
    # Peel a leading wrapper word or a VAR=val assignment, re-stripping each time — so `sudo rm`,
    # `xargs rm`, `FOO=bar rm x` expose the real command. (Subshell/brace delimiters were folded to
    # spaces above, so `(git commit)` / `{ rm x; }` need no separate peel here.)
    while :; do
        case "$seg" in
            "sudo "*|"xargs "*|"time "*|"env "*|"nice "*|"nohup "*|"command "*)
                seg="${seg#* }" ;;
            [A-Za-z_]*=*)
                case "${seg%% *}" in           # only if the FIRST token is itself NAME=val (not `cmd a=b`)
                    *=*) seg="${seg#* }" ;;
                    *) break ;;
                esac ;;
            *) break ;;
        esac
        seg="${seg#"${seg%%[![:space:]]*}"}"
    done

    # git: match by SUBCOMMAND, tolerating global options (`-C <path>`, `-c k=v`, `--no-pager`, ...).
    case "$seg" in
        "git "*)
            rest="${seg#git }"
            rest="${rest#"${rest%%[![:space:]]*}"}"
            while :; do
                case "$rest" in
                    "-C "*|"-c "*|"--git-dir "*|"--work-tree "*|"--namespace "*|"--exec-path "*|"--super-prefix "*)
                        rest="${rest#* }"; rest="${rest#* }" ;;   # global flag + its separate argument
                    "-"*" "*) rest="${rest#* }" ;;                 # any other global option token
                    "-"*) rest="" ;;                               # a trailing lone option -> no subcommand
                    *) break ;;
                esac
                rest="${rest#"${rest%%[![:space:]]*}"}"
            done
            case "${rest%% *}" in
                stash)
                    # `stash list` / `stash show` are read-only views; bare `stash` and the rest mutate
                    after="${rest#stash}"; after="${after#"${after%%[![:space:]]*}"}"
                    case "${after%% *}" in
                        list|show) ;;
                        *) deny="$seg"; break ;;
                    esac ;;
                commit|push|add|reset|restore|rm|checkout|clean|switch)
                    deny="$seg"; break ;;
            esac
            ;;
    esac

    # other unambiguous source-mutation / destructive / publish idioms
    case "$seg" in
        "sed -i"*|"sed --in-place"*|\
        "rm "*|rm|"rmdir "*|rmdir|"mv "*|"chmod "*|"chown "*|\
        "npm publish"*|"yarn publish"*|"pnpm publish"*)
            deny="$seg"; break ;;
    esac
done
IFS="$oldifs"

if [ -n "$deny" ]; then
    printf 'read-only guard: blocked a write-ish/destructive Bash command:\n  %s\nswarm-agents read-only workers re-run Verify and report — they do not mutate source. Make the change a separate task. (toolable/partial — a tripwire, not a guarantee.)\n' "$cmd" >&2
    exit 2
fi

exit 0
