---
name: guide-rewrite
description: Rewrite a rough, terse, or under-specified request into a prompt that follows the official prompting guide for the model running it (Anthropic's Claude guides for Fable 5.1 and Opus 5.5; OpenAI's GPT-6 and Codex guides in Codex or ChatGPT), then carry it out. Use only when the user invokes it: "/guide-rewrite …", "$guide-rewrite …", "프롬프트 개선해서", "가이드에 맞게 요청해", "제대로 시켜줘", "improve this prompt", "prompt it properly". Do not trigger on ordinary requests by yourself.
---
# guide-rewrite · guide-aligned request rewrite (per-request layer)

Source: Anthropic docs "Prompting Claude Fable 5.1" (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1), "Prompting Claude Opus 5.5" (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5) and "Prompting Claude Opus 5" (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5), which the Opus 5.5 guide names as its starting point.
OpenAI: "Using GPT-6", Codex "Best practices" and related pages, listed at the top of `references/openai-blocks.md`.
Fixed guide blocks: `references/prompt-blocks.md` (Claude), `references/openai-blocks.md` (OpenAI GPT).
Before/after samples: `references/examples.md`.

## Step 0 · Pick the guide set
Use the set that matches the model you are running on. You know your own model; do not ask.
- **Claude** (Claude Code): `references/prompt-blocks.md`, and the rules below about the plugin hook apply.
- **OpenAI GPT** (Codex, ChatGPT): `references/openai-blocks.md`. No plugin hook runs there, so nothing is
  pre-injected; attach only the O-blocks that Step 3 item 6 names for this request, and treat the user's
  `AGENTS.md` as the always-on layer. The lettered Claude blocks (A to M) never go into a GPT request.

This skill handles the **per-request layer** only: the four fields every request needs, plus the guide
blocks that depend on the request. The always-on rules (autonomy, scope limits, scope of the deliverable,
targeted edits, progress updates, formatting, batching, and early stops in unattended sessions) are injected in Claude Code by this plugin's SessionStart hook, so never repeat them here. The same hook also injects model-specific rules for the session's model (Fable 5.1, Opus 5.5, Opus 5, Sonnet 5); they are already in context, so don't repeat them either, and pick effort guidance for that model from references/prompt-blocks.md.

## Mode
- **Default: rewrite, show, then execute in the same turn.** Do not stop after showing the prompt.
- **Show only** when the user says "프롬프트만", "보여만 줘", "just the prompt", "don't run it".
- Never ask the user to write the prompt. Build it from conversation context.

## Step 1 · Resolve referents
Fill "이거", "그거", "this", "that file", "the error" from context in this order: last path mentioned, last
error text, last artifact produced, current git diff, open thread. Write the resolved value as a concrete
path, symbol, or quote.

Ask exactly one question (with options and a recommended pick) only when different readings would lead
to **materially different work**. Routine ambiguity: pick the reading the wording and surrounding code
most directly support and state the assumption inside the prompt.

## Step 2 · Classify
| Kind | Signal | Deliverable |
|---|---|---|
| Change | build/fix/change verbs | working change + verification evidence |
| Assessment | user describes a problem, asks why, thinks out loud | findings only, **no fix** until asked (guide exception) |
| Research | look up, investigate, names of tools or models, anything time-sensitive | sourced answer; search the name as the user wrote it |
| Writing | write, summarise, draft a doc or post | text in the requested shape, no mannered prose |
| Long deliverable | full rewrite, multi-section doc, big table, whole file | as above plus the long-output note (block G) |

## Step 3 · Compose
Write task-specific parts (goal, context, scope, done) in the user's language so they can check them. Keep every guide block in English verbatim; never translate a block.

1. **Goal** · one sentence, outcome-verifiable.
2. **Context** · resolved paths, symbols, error text, related decisions.
3. **Scope** · what is in, what is explicitly out.
4. **Done criteria** · the exact check: a command, a count, a file that must exist, a reproduced workflow.
5. **Effort** · do not write an effort line into the request; a line in a prompt changes nothing in Claude Code.
   Effort is a setting (`/effort` saves it per model in `modelSettings`; `CLAUDE_CODE_EFFORT_LEVEL` overrides). Mention it only when it
   matters for this request: time-sensitive research at `low` → add block **H**; a long deliverable at `xhigh`
   → add block **G**.
   GPT: effort is `/model` or `model_reasoning_effort` in Codex; see "Reasoning effort" in `openai-blocks.md`.
6. **Conditional blocks** · Assessment → the "report findings, don't fix" sentence. Research/summary →
   block **J** (quoting example). Writing → block **F** (short form). Code task → phrase checks as
   "Are there any bugs?" not "Does it compile?" (safeguard false positives).
   GPT instead: multi-step Change → **O1**; Change that ends in deploy, publish, merge or an external write →
   **O2**; small or reversible code change → **O8**; a skill or `AGENTS.md` rule pulling against the request →
   **O3**; Writing → **O4** (+ **O5** when needed); Assessment → the "report findings, don't fix" sentence,
   plus **O6** for a non-technical reader; parallel work the user asked to split → **O7**.

**Claude: never attach blocks A, B, C, D, E, I, L, or M.** They are already active through the plugin hook.
**GPT: at most three O-blocks per request**; if the same block keeps coming back, suggest moving it into
`AGENTS.md` in the recap. The improved
request stays short: four fields, effort, and only the conditional lines from item 6.

## Step 4 · Show, then run
Print the prompt in one fenced block titled `개선된 요청` (or `Improved request`), four fields only plus any conditional lines, then execute it as if
the user had sent it. Open with one line on what you are doing, give brief updates, and close with a
recap that stands on its own. End with exactly one status: DONE, DONE_WITH_CONCERNS, BLOCKED, or NEEDS_CONTEXT.

## Do not
- Do not widen the task while improving it. The rewrite clarifies; it does not add features.
- Do not turn an Assessment into a Change.
- Do not paraphrase block A's first paragraph; its opening sentence carries most of the effect.
- Claude: do not add anti-formatting rules; the conditional formatting rule (block I) is already active.
