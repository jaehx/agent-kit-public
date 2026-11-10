#!/usr/bin/env bash
# Fails when the text the hook injects nears Claude Code's 10,000-character cap on additionalContext. Past the cap
# Claude gets a file path and a 2,000-character preview instead, and nothing can raise it (hooks doc, JSON output).
# It counts bytes, which are never fewer than characters, so the result does not depend on the caller's locale.
# Run before a release: bash tests/context-size.sh
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIMIT=9000
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/cfg" "$TMP/proj"
fail=0

# check LABEL BYTES: one line per measured text, and a failure when it is over the limit
check() {
  printf '%-48s %5s bytes\n' "$1" "$2"
  [ "$2" -le "$LIMIT" ] || { echo "  over $LIMIT: $1"; fail=1; }
}
# hook-only delivery (no rules file in the empty config folder), run by hand so the output is the plain context
# followed by a blank line and the status line in parentheses. A third argument names the session model (prompt-polish
# adds that model's rules file); stdin without hook_event_name still counts as run by hand.
context() {
  printf '{"model":"%s"}' "${3:-}" | CLAUDE_CONFIG_DIR="$TMP/cfg" CLAUDE_PROJECT_DIR="$TMP/proj" CLAUDE_CODE_ENTRYPOINT="$1" CLAUDE_CODE_EFFORT_LEVEL="$2" \
    bash "$ROOT/hooks/session-start.sh" | sed '/^(prompt-polish /,$d' | wc -c | tr -d ' '
}
check "session start, interactive, high effort" "$(context cli high)"
check "session start, interactive, max effort" "$(context cli max)"
check "session start, unattended, max effort" "$(context sdk-cli max)"
for m in claude-fable-5-2 claude-opus-5-5 claude-opus-5 claude-sonnet-5-5 claude-sonnet-5 claude-haiku-5-5; do
  check "unattended, max effort, $m" "$(context sdk-cli max "$m")"
done
check "subagent start (hooks/subagent.md)" "$(wc -c < "$ROOT/hooks/subagent.md" | tr -d ' ')"
exit "$fail"
