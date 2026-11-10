#!/usr/bin/env bash
# prompt-polish: keeps the hook fast. On Windows (Git Bash) starting a process or a subshell costs tens of
# milliseconds, and the hook once took 4.6 s inside a real session against a 5 s timeout because it started well over
# a hundred of them. Two checks:
#   1. hooks/session-start.sh has no command substitution, backticks or pipes outside comments, so every helper keeps
#      returning its result in REPLY.
#   2. one SessionStart run and one SubagentStart run each finish within LIMIT_MS (default 1500).
# Run before a release: bash tests/hook-speed.sh
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
H="$ROOT/hooks/session-start.sh"
LIMIT_MS="${LIMIT_MS:-1500}"
fail=0

code="$(grep -n -v '^[[:space:]]*#' "$H" | sed 's/[[:space:]]#[[:space:]].*$//')"   # numbered lines, comments dropped
hits="$(printf '%s\n' "$code" | grep -E '\$\(|`|[^|]\|[^|]' | grep -v -E 'case |\) [A-Za-z_]+=|\|\*|[a-z0-9-]\|[a-z0-9*-]')"
if [ -n "$hits" ]; then echo "command substitution, backtick or pipe in the hook:"; printf '%s\n' "$hits"; fail=1
else echo "no command substitution, backtick or pipe in the hook"; fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/cfg" "$TMP/proj"
now_ms() { local n; n="$(date +%s%N)"; echo $(( n / 1000000 )); }
timed() {   # LABEL JSON
  local s e
  s="$(now_ms)"
  printf '%s' "$2" | CLAUDE_CONFIG_DIR="$TMP/cfg" CLAUDE_PROJECT_DIR="$TMP/proj" CLAUDE_CODE_ENTRYPOINT=cli bash "$H" >/dev/null
  e="$(now_ms)"
  printf '%-16s %5s ms\n' "$1" "$(( e - s ))"
  [ "$(( e - s ))" -le "$LIMIT_MS" ] || { echo "  over $LIMIT_MS ms: $1"; fail=1; }
}
timed "session start" '{"hook_event_name":"SessionStart","source":"startup","model":"claude-fable-5-2"}'
timed "subagent start" '{"hook_event_name":"SubagentStart","agent_type":"Explore"}'
exit "$fail"
