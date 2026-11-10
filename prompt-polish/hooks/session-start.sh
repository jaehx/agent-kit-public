#!/usr/bin/env bash
# oh-my-fable hook. Three events, one script:
#   SessionStart    · the always-on working rules for the main session (plus a one-line status for the user)
#   SubagentStart   · a short version of the rules for subagents spawned with the Agent tool (forks skipped)
#   PostModelSwitch · the new model's rules after a mid-session model switch, and block N when it runs at xhigh or max
#   --status      · print what is in effect (used by /guide-status); writes nothing
# prompt-polish (fork) adds a model layer: hooks/models/<name>.md is appended for the session's model in states 2
# and 4 below, and swapped on PostModelSwitch. See model_file.
#
# Config (optional). Global: $CLAUDE_CONFIG_DIR/oh-my-fable.json (default ~/.claude)  Project: $CLAUDE_PROJECT_DIR/.claude/oh-my-fable.json
#   {"enabled": true, "mode": "auto" | "interactive" | "unattended", "delivery": "hook" | "rules-file" | "claude-md"}
# mode "auto" (default): unattended when Claude Code was started through the SDK or headless mode
# (CLAUDE_CODE_ENTRYPOINT is sdk-cli, sdk-ts, or sdk-py; `claude -p`, Agent SDK apps, and agent harnesses set
# this), interactive otherwise (terminal, IDE). The SessionStart hook input carries no permission mode and not always the model,
# so the entrypoint is the only per-session signal.
# Merge rule: a project file may only turn the plugin OFF ("enabled": false). "mode" and "delivery" are read
# from the global file only, so a cloned repository cannot switch an agent to unattended mode.
# Defaults: enabled, auto, hook.
#
# Where the base rules come from, in this order:
#   1. a CLAUDE.md section between oh-my-fable:start / oh-my-fable:end (static, user-managed): hook stays silent
#   2. rules/oh-my-fable.md written by /guide-setup (marker oh-my-fable:rules vN): Claude Code auto-loads it for the
#      main session, regular subagents and teams; the hook adds only the unattended paragraphs per session and
#      warns once per session when the plugin ships a newer version of that file (or, when the file is newer than
#      this plugin copy, says to start a new session instead of refreshing)
#   3. any other rules/oh-my-fable.md (user-managed): hook stays silent
#   4. nothing else: the hook carries everything (hook only)
# Effort: when the level resolved at SessionStart is xhigh or max, the hook also adds effort-high.md (block N, from
# the Sonnet 5.5 guide: stop after the checks pass, no self-started review rounds) in states 2 and 4.
# Subagents: Explore and Plan never load CLAUDE.md or rules files, so they get the short rules from this hook
# whenever the plugin is enabled. Other subagents get the short rules only in hook-only delivery (otherwise the
# rules file or CLAUDE.md section already reaches them).
# A custom subagent whose definition sets omitClaudeMd: true (Claude Code 2.1.271+) loads no rules files either:
# measured 2026-09-29 on 2.1.284, such an agent saw neither ~/.claude/rules/*.md, the project's .claude/rules/*.md,
# nor CLAUDE.md, while the same agent without the flag saw all three. SubagentStart input carries only agent_type,
# not the agent's definition, so the hook cannot tell these agents apart: under hook-only delivery they get the short
# rules like every subagent; under the other deliveries they get nothing from this plugin. That fits the flag's
# purpose (a lean context); a rule that must reach such an agent belongs in its delegation prompt or its own prompt.
#
# Output: plain text when run by hand (no hook JSON on stdin); JSON with additionalContext / systemMessage when
# Claude Code runs it. No python, jq, or other runtime is needed (macOS, Linux, Windows Git Bash).
set -u
export LC_ALL=C
# prompt-polish: everything below uses bash builtins only (no grep, sed, tr, awk, cat, or command substitution).
# On Windows (Git Bash) each external process or subshell costs tens of milliseconds, and the earlier version, which
# started well over a hundred of them, took 4.6 s inside a real session (measured 2026-11-10 on 2.1.316) against a
# 5 s hook timeout. Helpers therefore return their result in REPLY instead of printing it. Keep it that way: a
# "$(helper ...)" brings the cost back. Written for bash 3.2 and later (macOS ships 3.2).
HERE="${BASH_SOURCE[0]%[/\\]*}"; [ "$HERE" = "${BASH_SOURCE[0]}" ] && HERE=.
PROJ="${CLAUDE_PROJECT_DIR:-.}"
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"   # Claude Code moves settings, rules and plugins with CLAUDE_CONFIG_DIR
GLOBAL="$CFG/oh-my-fable.json"
LOCAL="$PROJ/.claude/oh-my-fable.json"
STATUS=false; [ "${1:-}" = "--status" ] && STATUS=true
# control characters by name: old bash versions disagree on $'...' written inside a quoted ${...}
NL=$'\n'; CR=$'\r'; TAB=$'\t'; P2="$NL$NL"

# slurp FILE: REPLY = the file's text without carriage returns and trailing newlines; empty when there is no file
slurp() {
  REPLY=""; [ -f "$1" ] || return 0
  IFS= read -r -d '' REPLY < "$1" || true
  REPLY=${REPLY//"$CR"/}
  while [ "${REPLY%"$NL"}" != "$REPLY" ]; do REPLY=${REPLY%"$NL"}; done
}
# key_val KEY TEXT: REPLY = the value of the first "KEY":"value" in TEXT; empty if absent
key_val() { local re="\"$1\":\"([^\"]*)\""; REPLY=""; [[ $2 =~ $re ]] && REPLY="${BASH_REMATCH[1]}"; return 0; }

# hook input (JSON on stdin); empty when run by hand or with --status
IN=""
if [ "$STATUS" = false ] && [ ! -t 0 ]; then IFS= read -r -d '' IN || true; fi
IN="${IN//[[:space:]]/}"
jget() { key_val "$1" "$IN"; }
jget hook_event_name; EVENT="$REPLY"; jget source; SOURCE="$REPLY"; jget agent_type; AGENT="$REPLY"
# a fork inherits the whole conversation, these rules included (sub-agents doc): nothing to add, so stop before any work
[ "$EVENT" = SubagentStart ] && [ "$AGENT" = fork ] && exit 0

# prompt-polish: REPLY = the rules file in hooks/models/ for canonical model id $1; empty when there is none.
# Each version is matched exactly. A model this table does not know gets no model rules and the status line says so,
# instead of silently getting an older model's rules. When a model ships, add its file and a line here.
# Fable 5.1 has no file: every prompt its guide gives is already in the base rules (always-on.md).
# Lines opening with <!-- in a rules file are notes for tests/guide-verbatim.sh and are not injected.
model_file() {
  case "$1" in
    *fable-5-2|*mythos-5-2) REPLY=fable-5-2;;
    *opus-5-5) REPLY=opus-5-5;;
    *opus-5) REPLY=opus-5;;
    *sonnet-5-5) REPLY=sonnet-5-5;;
    *sonnet-5) REPLY=sonnet-5;;
    *haiku-5-5) REPLY=haiku-5-5;;
    *) REPLY="";;
  esac
}
# REPLY = the model's rules with a one-line factual lead-in, for $RULES_MODEL; empty when model_file has no file for it.
# The lead-in ties the rules to the model by name: rules injected earlier cannot be removed after a /model switch,
# so each set says it holds only while that model is the one running. When the model was read from settings
# (RULES_GUESSED), the lead-in says so and leaves the check to the model, which knows its own id.
model_paragraph() {
  local lead line body=""
  model_file "$RULES_MODEL"; [ -n "$REPLY" ] || return 0
  if [ "$RULES_GUESSED" = true ]; then
    lead="This session did not report its model; the user's settings name $RULES_MODEL. The user's standing rules for $RULES_MODEL follow. They apply only if you are $RULES_MODEL; if you are a different model, ignore them."
  else
    lead="This session's model is $RULES_MODEL. The user's standing rules for that model follow; they apply only while you are $RULES_MODEL."
  fi
  slurp "$HERE/models/$REPLY.md"
  while IFS= read -r line; do
    case "$line" in '<!--'*) ;; *) body="$body$line$NL";; esac
  done <<EOF
$REPLY
EOF
  while [ "${body%"$NL"}" != "$body" ]; do body=${body%"$NL"}; done
  REPLY="$lead$P2$body"
}

# val FILE KEY: REPLY = a JSON string/bool value for KEY in FILE, ignoring whitespace; empty if absent
val() { local re="\"$2\":\"?([A-Za-z-]*)"; slurp "$1"; local s="${REPLY//[[:space:]]/}"; REPLY=""; [[ $s =~ $re ]] && REPLY="${BASH_REMATCH[1]}"; return 0; }
# jesc TEXT: REPLY = TEXT escaped for a JSON string (backslash, quote, tab, newline)
BS='\'; DQ='"'
jesc() {
  REPLY=${1//"$BS"/$BS$BS}
  REPLY=${REPLY//"$DQ"/$BS$DQ}
  REPLY=${REPLY//"$TAB"/${BS}t}
  REPLY=${REPLY//"$NL"/${BS}n}
}
slurp "$HERE/../.claude-plugin/plugin.json"; VERSION=""; RE='"version":[ ]*"([^"]*)"'; [[ $REPLY =~ $RE ]] && VERSION="${BASH_REMATCH[1]}"

ENABLED=true; MODE=auto; DELIVERY=hook
val "$GLOBAL" enabled; [ "$REPLY" = "false" ] && ENABLED=false
val "$LOCAL" enabled; [ "$REPLY" = "false" ] && ENABLED=false
val "$GLOBAL" mode; case "$REPLY" in interactive|unattended) MODE="$REPLY";; esac
AUTO=""
if [ "$MODE" = auto ]; then
  case "${CLAUDE_CODE_ENTRYPOINT:-}" in sdk-cli|sdk-ts|sdk-py) MODE=unattended;; *) MODE=interactive;; esac
  AUTO=" (auto)"
fi
val "$GLOBAL" delivery; [ -n "$REPLY" ] && DELIVERY="$REPLY"

# Where do the base rules come from? STATE: disabled | claude-md | rules-file | user-rules | hook-only
RE_RULES='oh-my-fable:rules v([0-9]*)'
STATE=hook-only; BASE=""; RULES_V=""; PLUGIN_V=""
slurp "$HERE/rules-file.md"; [[ $REPLY =~ $RE_RULES ]] && PLUGIN_V="${BASH_REMATCH[1]}"
for f in "$CFG/CLAUDE.md" "$PROJ/CLAUDE.md" "$PROJ/.claude/CLAUDE.md"; do
  [ -f "$f" ] || continue
  slurp "$f"
  case "$REPLY" in *oh-my-fable:start*) STATE=claude-md; BASE="$f"; break;; esac
done
if [ "$STATE" = hook-only ]; then
  for f in "$PROJ/.claude/rules/oh-my-fable.md" "$CFG/rules/oh-my-fable.md"; do
    [ -f "$f" ] || continue
    BASE="$f"
    slurp "$f"; [[ $REPLY =~ $RE_RULES ]] && RULES_V="${BASH_REMATCH[1]}"
    if [ -n "$RULES_V" ]; then STATE=rules-file; else STATE=user-rules; fi
    break
  done
fi
[ "$STATE" = hook-only ] && [ "$DELIVERY" = claude-md ] && STATE=claude-md   # config says CLAUDE.md, section not found yet
[ "$ENABLED" = true ] || STATE=disabled

# effort, shown in the startup status line and used for the xhigh/max paragraph. Claude Code sets CLAUDE_EFFORT (and
# the effort input field) only inside tool-use contexts, never for SessionStart (hooks doc, common input fields;
# measured on 2.1.280), so a CLAUDE_EFFORT seen at SessionStart was inherited from a parent session's Bash tool and
# describes that session: ignored. With --status (run by the Bash tool inside the session) CLAUDE_EFFORT is the live
# level and wins. Otherwise: the env override, then the user settings file, where modelSettings.<canonical
# model>.effortLevel beats the top-level effortLevel, then the model's default (model-config doc). A maxEffortLevel
# (modelSettings.<model>.maxEffortLevel, else top-level) caps whatever was resolved, the default included (settings
# reference). Only the user settings file is read; levels and caps from project or managed settings are not seen.
# `claude -p` sends SessionStart no model field (measured 2026-09-29 on 2.1.284), so headless runs resolve effort
# only from CLAUDE_CODE_EFFORT_LEVEL; without it the status line shows none and block N is not added. After /clear or
# a compaction the model can be omitted too (hooks doc); the session keeps the model it ran, normally the one /model
# saved to the user settings' `model` field (model-config doc), so there it is read from that field.
# Per model: the default effort and whether a user-scope top-level effortLevel is ignored ("Opus 5.5 and models
# released after it", model-config doc). When a model ships, extend this table, and the alias map in
# model_from_settings when an alias moves to it.
model_traits() {   # sets DEFAULT_EFFORT and IGNORES_TOP for model $1
  IGNORES_TOP=false
  case "$1" in
    claude-fable-5-2*|claude-mythos-5-2*|claude-opus-5-5*|claude-sonnet-5-5*|claude-haiku-5-5*) DEFAULT_EFFORT=medium; IGNORES_TOP=true;;
    claude-opus-4-7*) DEFAULT_EFFORT=xhigh;;
    *) DEFAULT_EFFORT=high;;
  esac
}
# canon ID: REPLY = the canonical id: no [1m], no date suffix
RE_DATED='^(.*)-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$'
canon() { REPLY="${1%'[1m]'}"; [[ $REPLY =~ $RE_DATED ]] && REPLY="${BASH_REMATCH[1]}"; return 0; }
# top_val KEY: REPLY = the first "KEY":"value" in the settings outside per-model objects. Every `"name":{...}` object
# with no nested braces that holds the key is dropped first, left to right without rescanning, as `sed s///g` did.
top_val() {
  local s="$SJ" out="" m re="\"[^\"]*\":[{][^{}]*\"$1\":\"[^\"]*\"[^{}]*[}]"
  while [[ $s =~ $re ]]; do
    m="${BASH_REMATCH[0]}"; out="$out${s%%"$m"*}"; s="${s#*"$m"}"
  done
  key_val "$1" "$out$s"
}
# REPLY = the settings' model in Claude Code's order (ANTHROPIC_MODEL, settings, ANTHROPIC_DEFAULT_MODEL). An alias
# maps to what it means on the Anthropic API today (model-config alias table); with a third-party provider aliases
# mean older models, so only the ANTHROPIC_DEFAULT_<FAMILY>_MODEL overrides count. best, opusplan and default stay unknown.
model_from_settings() {
  local m over def
  m="${ANTHROPIC_MODEL:-}"
  [ -n "$m" ] || { top_val model; m="$REPLY"; }
  [ -n "$m" ] || m="${ANTHROPIC_DEFAULT_MODEL:-}"
  canon "$m"; m="$REPLY"; REPLY=""
  case "$m" in
    opus)   over="${ANTHROPIC_DEFAULT_OPUS_MODEL:-}";   def=claude-opus-5-5;;
    sonnet) over="${ANTHROPIC_DEFAULT_SONNET_MODEL:-}"; def=claude-sonnet-5-5;;
    haiku)  over="${ANTHROPIC_DEFAULT_HAIKU_MODEL:-}";  def=claude-haiku-5-5;;
    fable)  over="${ANTHROPIC_DEFAULT_FABLE_MODEL:-}";  def=claude-fable-5-2;;
    claude-*) REPLY="$m"; return 0;;
    *) return 0;;
  esac
  if [ -n "$over" ]; then canon "$over"; return 0; fi
  [ -n "${CLAUDE_CODE_USE_BEDROCK:-}${CLAUDE_CODE_USE_VERTEX:-}${CLAUDE_CODE_USE_FOUNDRY:-}${CLAUDE_CODE_USE_ANTHROPIC_AWS:-}${CLAUDE_CODE_USE_MANTLE:-}" ] || REPLY="$def"
  return 0
}
level_rank() { case "$1" in low) REPLY=1;; medium) REPLY=2;; high) REPLY=3;; xhigh) REPLY=4;; max) REPLY=5;; *) REPLY=0;; esac; }
EFFORT=""; SRC=""; HIGH_EFFORT=false; MODEL_NOTE=""; MODEL=""
SJ=""; if [ "$EVENT" != SubagentStart ]; then slurp "$CFG/settings.json"; SJ="${REPLY//[[:space:]]/}"; fi
# resolve_effort: sets EFFORT, SRC and HIGH_EFFORT for $MODEL (may be empty); MODEL_NOTE follows a source read for it
resolve_effort() {
  local s re m cap_rank
  EFFORT=""; SRC=""; HIGH_EFFORT=false
  MOBJ=""   # every "<model>":{...} object in the settings, one per line
  if [ -n "$MODEL" ]; then
    s="$SJ"; re="\"$MODEL\":[{][^}]*[}]"
    while [[ $s =~ $re ]]; do m="${BASH_REMATCH[0]}"; MOBJ="$MOBJ$m$NL"; s="${s#*"$m"}"; done
  fi
  if [ "$STATUS" = true ] && [ -n "${CLAUDE_EFFORT:-}" ]; then EFFORT="$CLAUDE_EFFORT"; SRC=live
  elif [ -n "${CLAUDE_CODE_EFFORT_LEVEL:-}" ]; then EFFORT="$CLAUDE_CODE_EFFORT_LEVEL"; SRC=env
  elif [ -n "$MODEL" ]; then
    model_traits "$MODEL"
    key_val effortLevel "$MOBJ"; PER_MODEL="$REPLY"
    TOP=""; IGNORED=""; [ -n "$PER_MODEL" ] || { top_val effortLevel; TOP="$REPLY"; }
    if [ -n "$TOP" ] && [ "$IGNORES_TOP" = true ]; then IGNORED=", top-level effortLevel $TOP ignored"; TOP=""; fi
    if [ -n "$PER_MODEL" ]; then EFFORT="$PER_MODEL"; SRC=saved
    elif [ -n "$TOP" ]; then EFFORT="$TOP"; SRC=settings
    else EFFORT="$DEFAULT_EFFORT"; SRC="model default$IGNORED"; fi
    SRC="$SRC$MODEL_NOTE"
  fi
  key_val maxEffortLevel "$MOBJ"; CAP="$REPLY"; [ -n "$CAP" ] || { top_val maxEffortLevel; CAP="$REPLY"; }
  level_rank "$CAP"; cap_rank="$REPLY"; level_rank "$EFFORT"
  if [ -n "$EFFORT" ] && [ "$cap_rank" -gt 0 ] && [ "$REPLY" -gt "$cap_rank" ]; then
    SRC="$SRC, $EFFORT → $CAP by maxEffortLevel"; EFFORT="$CAP"
  fi
  case "$EFFORT" in xhigh|max) HIGH_EFFORT=true;; esac
}
# REPLY = block N with its one-line lead-in, for the effort resolved last
high_paragraph() { slurp "$HERE/effort-high.md"; REPLY="This session runs at $EFFORT effort ($SRC); the user's standing rule for that level follows.$P2$REPLY"; }
if [ "$STATUS" = true ] || [ -z "$EVENT" ] || [ "$EVENT" = SessionStart ]; then
  jget model; canon "$REPLY"; MODEL="$REPLY"
  if [ "$STATUS" = true ]; then canon "${2:-}"; MODEL="$REPLY"; fi   # prompt-polish: --status <model id> names the model rules too
  if [ -z "$MODEL" ] && [ "$EVENT" = SessionStart ] && [ "$SOURCE" != startup ]; then
    model_from_settings; MODEL="$REPLY"; [ -n "$MODEL" ] && MODEL_NOTE=", model $MODEL from settings"
  fi
  resolve_effort
fi
# prompt-polish: the model the rules are chosen for. A headless start carries no model field, even with --model
# (measured 2026-11-10 on 2.1.316 with a hook that logged its input), so there the settings' model stands in and
# the lead-in tells the model to ignore the rules if it is a different one. Effort keeps upstream's stricter rule
# above and is not guessed at startup: a wrong effort would add block N with nothing to catch it.
RULES_MODEL="$MODEL"; RULES_GUESSED=false
[ -n "$MODEL_NOTE" ] && RULES_GUESSED=true
if [ -z "$RULES_MODEL" ] && [ "$EVENT" = SessionStart ]; then
  model_from_settings; RULES_MODEL="$REPLY"; [ -n "$RULES_MODEL" ] && RULES_GUESSED=true
fi
EFFORT_SHOWN="${EFFORT:+ · effort $EFFORT ($SRC)}"; [ -n "$EFFORT" ] || EFFORT="(not known at session start; /effort shows it)"

case "$STATE" in
  claude-md)  HOW="CLAUDE.md section; hook silent";;
  rules-file) HOW="rules file v$RULES_V + hook";;
  user-rules) HOW="user-managed rules file; hook silent";;
  hook-only)  HOW="hook only";;
  disabled)   HOW="disabled by config";;
esac
STATUS_LINE="prompt-polish ${VERSION:-?} · mode $MODE$AUTO · rules: $HOW$EFFORT_SHOWN"
# model rules go out in the two states where the hook speaks (rules-file, hook-only); a known model with no file is named
MODEL_RULES=""
case "$STATE" in rules-file|hook-only)
  if [ -n "$RULES_MODEL" ]; then
    model_file "$RULES_MODEL"; MODEL_RULES="$REPLY"
    STATUS_LINE="$STATUS_LINE · model rules: ${MODEL_RULES:-none for $RULES_MODEL}"
    [ "$RULES_GUESSED" = true ] && STATUS_LINE="$STATUS_LINE (model from settings)"
  fi;;
esac
# a rules file newer than this plugin copy: the session started before an update, or this folder's plugin is older
NOTICE=""
if [ "$STATE" = rules-file ] && [ -n "$PLUGIN_V" ]; then
  if [ "$RULES_V" -lt "$PLUGIN_V" ]; then
    NOTICE="oh-my-fable: your rules file is v$RULES_V, the plugin ships v$PLUGIN_V. Run /guide-setup refresh to update it."
  elif [ "$RULES_V" -gt "$PLUGIN_V" ]; then
    NOTICE="oh-my-fable: your rules file is v$RULES_V, newer than the v$PLUGIN_V this plugin ships, so this session runs an older plugin. Start a new session (update the plugin first if it is not updated yet). Don't run /guide-setup refresh: it would downgrade the file."
  fi
fi

if [ "$STATUS" = true ]; then
  case "$STATE" in
    disabled|user-rules) SUB="nothing from the hook";;
    hook-only) SUB="short rules to every subagent (SubagentStart hook)";;
    *) SUB="base file reaches regular subagents; Explore and Plan get the short rules from the hook";;
  esac
  printf 'plugin_version: %s\nconfig_dir: %s\nproject_dir: %s\nentrypoint: %s\nenabled: %s\nmode: %s%s\ndelivery_config: %s\nrules_source: %s\nbase_file: %s\nrules_file_version: %s\nplugin_rules_version: %s\neffort: %s\neffort_source: %s\nmodel_rules: %s\nsubagents: %s\nnotice: %s\n' \
    "${VERSION:-?}" "$CFG" "$PROJ" "${CLAUDE_CODE_ENTRYPOINT:-(none, interactive)}" "$ENABLED" "$MODE" "$AUTO" "$DELIVERY" "$STATE" "${BASE:-(none)}" "${RULES_V:-(n/a)}" "${PLUGIN_V:-?}" "$EFFORT" "${SRC:-(n/a)}" "${MODEL_RULES:-(none${RULES_MODEL:+ for $RULES_MODEL})}" "$SUB" "${NOTICE:-(none)}"
  exit 0
fi

[ "$STATE" = disabled ] && exit 0

# ---------- SubagentStart ----------
if [ "$EVENT" = SubagentStart ]; then
  case "$STATE" in
    user-rules) exit 0;;
    hook-only) ;;
    *) case "$AGENT" in Explore|Plan) ;; *) exit 0;; esac;;
  esac
  slurp "$HERE/subagent.md"; jesc "$REPLY"
  printf '{"hookSpecificOutput":{"hookEventName":"SubagentStart","additionalContext":"%s"}}\n' "$REPLY"
  exit 0
fi

# ---------- PostModelSwitch ----------
# The session's model changed (2.1.251+; hooks doc). Add block N when the new model runs at xhigh or max. A paragraph
# injected earlier cannot be taken back, and a switch between two such models repeats it, which is harmless. A resume
# restores the model and replays the earlier context, so it adds nothing.
# prompt-polish: when the switch moves between models with different rules files, say that the earlier model rules
# no longer apply and give the new model's rules (earlier text cannot be removed, only superseded).
if [ "$EVENT" = PostModelSwitch ]; then
  case "$STATE" in rules-file|hook-only) ;; *) exit 0;; esac
  [ "$SOURCE" = resume ] && exit 0
  jget to_model; canon "$REPLY"; MODEL="$REPLY"; resolve_effort
  RULES_MODEL="$MODEL"; RULES_GUESSED=false
  SWITCH=""
  model_file "$MODEL"; TO_FILE="$REPLY"; jget from_model; canon "$REPLY"; model_file "$REPLY"
  if [ "$TO_FILE" != "$REPLY" ]; then
    SWITCH="The session's model changed to ${MODEL:-an unknown model}. Model-specific rules given earlier in this conversation for another model no longer apply."
    model_paragraph; [ -n "$REPLY" ] && SWITCH="$SWITCH$P2$REPLY"
  fi
  if [ "$HIGH_EFFORT" = true ]; then high_paragraph; SWITCH="${SWITCH:+$SWITCH$P2}$REPLY"; fi
  [ -n "$SWITCH" ] || exit 0
  jesc "$SWITCH"
  printf '{"hookSpecificOutput":{"hookEventName":"PostModelSwitch","additionalContext":"%s"}}\n' "$REPLY"
  exit 0
fi

# ---------- SessionStart (or run by hand) ----------
# Each injected part opens with a one-line factual lead-in: the hooks doc asks for additionalContext written as
# factual statements, because text framed as out-of-band system commands can trigger prompt-injection defenses.
# The rule paragraphs themselves are unchanged.
if [ "$AUTO" = "" ]; then UNATTENDED_LEAD="The user set oh-my-fable to unattended mode for every session; the user's standing rules for such sessions follow."
else UNATTENDED_LEAD="This session was started headless (entrypoint ${CLAUDE_CODE_ENTRYPOINT:-unknown}); the user's standing rules for such sessions follow."; fi
slurp "$HERE/autonomy-unattended.md"; UNATTENDED="$UNATTENDED_LEAD$P2$REPLY"
high_paragraph; HIGH="$REPLY"
MODEL_PART=""; if [ -n "$MODEL_RULES" ]; then model_paragraph; MODEL_PART="$REPLY"; fi
CTX=""
case "$STATE" in
  claude-md|user-rules) ;;
  rules-file)   # the base rules come from the rules file; add only what depends on this session
    EXTRA=""
    [ "$MODE" = unattended ] && EXTRA="$UNATTENDED"
    [ "$HIGH_EFFORT" = true ] && EXTRA="${EXTRA:+$EXTRA$P2}$HIGH"
    [ -n "$MODEL_PART" ] && EXTRA="${EXTRA:+$EXTRA$P2}$MODEL_PART"
    [ -n "$EXTRA" ] && CTX="# Working rules (oh-my-fable), this session$P2$EXTRA";;
  hook-only)
    slurp "$HERE/always-on.md"; BODY="$REPLY"
    HEAD=${BODY%%"$NL"*}   # the heading line
    REST=""; [ "$HEAD" != "$BODY" ] && REST=${BODY#*"$NL"}
    CTX="The user installed prompt-polish; these are the user's standing working rules.$P2$HEAD"
    [ "$MODE" = unattended ] && CTX="$CTX$P2$UNATTENDED"
    CTX="$CTX$NL$REST"
    [ "$HIGH_EFFORT" = true ] && CTX="$CTX$P2$HIGH"
    [ -n "$MODEL_PART" ] && CTX="$CTX$P2$MODEL_PART";;
esac

if [ -z "$EVENT" ]; then
  # run by hand (/guide-setup verification, curious users): plain text, status last
  [ -n "$CTX" ] && printf '%s\n\n' "$CTX"
  printf '(%s)\n' "$STATUS_LINE"
  [ -n "$NOTICE" ] && printf '%s\n' "$NOTICE"
  exit 0
fi

# run by Claude Code: rules go to Claude's context, the status line goes to the user (new sessions only)
MSG=""
[ "$SOURCE" = startup ] && MSG="$STATUS_LINE"
[ -n "$NOTICE" ] && MSG="${MSG:+$MSG. }$NOTICE"
[ -z "$CTX" ] && [ -z "$MSG" ] && exit 0
OUT="{"
if [ -n "$CTX" ]; then jesc "$CTX"; OUT="$OUT\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"$REPLY\"}"; fi
[ -n "$CTX" ] && [ -n "$MSG" ] && OUT="$OUT,"
if [ -n "$MSG" ]; then jesc "$MSG"; OUT="$OUT\"systemMessage\":\"$REPLY\""; fi
printf '%s}\n' "$OUT"
exit 0
