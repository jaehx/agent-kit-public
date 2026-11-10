---
name: guide-rewrite
description: Rewrite a rough, terse, or under-specified request into a prompt that follows the official prompting guide for the model running it (Anthropic's Claude guides for Fable 5.2, Opus 5.5, Sonnet 5.5 and Haiku 5.5; OpenAI's GPT-6 and Codex guides in Codex or ChatGPT), then carry it out. Add "just the prompt" or "프롬프트만" to only see the rewrite.
argument-hint: "[request]"
disable-model-invocation: true
---
# guide-rewrite · guide-aligned request rewrite (per-request layer)

Source: Anthropic docs "Prompting Claude Fable 5.2" (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-2), "Prompting Claude Fable 5.1" (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1), "Prompting Claude Opus 5.5" (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5), "Prompting Claude Sonnet 5.5" (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5-5), "Prompting Claude Haiku 5.5" (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-haiku-5-5) and "Prompting Claude Opus 5" (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5), which the Opus 5.5 guide names as its starting point.
OpenAI: "Using GPT-6", Codex "Best practices" and related pages, listed at the top of `references/openai-blocks.md`.
Fixed guide blocks: `references/prompt-blocks.md` (Claude), `references/openai-blocks.md` (OpenAI GPT).
Before/after samples: `references/examples.md`.
The Claude blocks this skill attaches (F, G, H, J, P) are copied word for word under **Block texts** below, so no
file has to be opened before the block is printed.

## Step 0 · Pick the guide set
Use the set that matches the model you are running on. You know your own model; do not ask.
- **Claude** (Claude Code): `references/prompt-blocks.md`, and the rules below about the plugin hook apply.
- **OpenAI GPT** (Codex, ChatGPT): `references/openai-blocks.md`. No plugin hook runs there, so nothing is
  pre-injected; attach only the O-blocks that Step 3 item 6 names for this request, and treat the user's
  `AGENTS.md` as the always-on layer. The lettered Claude blocks (A to P) never go into a GPT request.
  `${CLAUDE_EFFORT}` in Step 3 is filled in only by Claude Code; skip that sentence when it shows unfilled.

This skill handles the **per-request layer** only: the four fields every request needs, plus the guide
blocks that depend on the request. The always-on rules (autonomy, scope limits, scope of the deliverable,
targeted edits, progress updates, formatting, batching, and early stops in unattended sessions) are injected in Claude Code by this plugin's SessionStart hook, so never repeat them here. The same hook also injects model-specific rules for the session's model (`hooks/models/`: Fable 5.2, Opus 5.5, Sonnet 5.5, Haiku 5.5, Opus 5, Sonnet 5); they are already in context, so don't repeat them either.

## Mode
- **Default: rewrite, show, then execute in the same turn.** Do not stop after showing the prompt.
- **Show only** when the user says "프롬프트만", "보여만 줘", "just the prompt", "don't run it".
- Never ask the user to write the prompt. Build it from conversation context.

## Step 1 · Resolve referents
Fill "이거", "그거", "this", "that file", "the error" from context in this order: last path mentioned, last
error text, last artifact produced, current git diff, open thread. Write the resolved value as a concrete
path, symbol, or quote. Resolve from what the conversation already holds; a referent that needs a lookup
(a file, the git diff) goes in as a stated assumption, checked once you are carrying out the request.

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
3. **Scope** · what is in, what is explicitly out. When the request includes a step that needs the user's
   go-ahead (deploy, send, delete, migrate), name the exact action that is approved or that must wait, not a
   category: Fable 5.2 applies an approval rule as written, and a broad one ("ask before contacting anyone")
   holds back routine work too.
4. **Done criteria** · the exact check: a command, a count, a file that must exist, a reproduced workflow. Write
   criteria that can be checked without a human (e.g. a command, a count, a file), not "looks right".
5. **Effort** · do not write an effort line into the request; a line in a prompt changes nothing in Claude Code.
   Effort is a setting (`/effort` saves it per model in `modelSettings`; `CLAUDE_CODE_EFFORT_LEVEL` overrides).
   This session runs at `${CLAUDE_EFFORT}` effort. Mention it only when it
   matters for this request: time-sensitive research at `low` → add block **H**; a long deliverable at `xhigh`
   or `max` → add block **G**. Never write a "think less" or "answer directly without deliberating" line into
   the request: on Fable 5.2, Opus 5.5, Sonnet 5.5 and Haiku 5.5 it does not reduce thinking. When the user wants
   a faster answer, say in the recap that a lower `/effort` level is what does it.
   GPT: effort is `/model` or `model_reasoning_effort` in Codex; see "Reasoning effort" in `openai-blocks.md`.
6. **Conditional blocks** · Assessment → the "report findings, don't fix" sentence. Research/summary →
   the line `+ block J` (J is too long for the block; follow it while you write the answer). Research on Sonnet 5.5 (any effort) → instead of block **H**, its guide's own
   search line, verbatim: `Use the search tool to check specifics that may have changed since your training, such as what is allowed, required or charged, even when you feel confident. For researched work such as a report or a comparison, gather current sources rather than writing from your training knowledge.` Research on Haiku 5.5 (any effort) → instead of block **H**, its guide's own search text, verbatim: `Your training data ends well before today's date. Records, office holders, prices, versions, rules and anything "latest" may have changed since then, so search for those before you answer, even when you feel sure. Facts that can't change need no search. When the answer depends on where the user is, put the user's country or region in the search query.` Writing → block **F** (short form). Code task → phrase checks as
   "Are there any bugs?" not "Does it compile?" (safeguard false positives). Change on Fable 5.2 where the user
   asked to restructure, consolidate or clean up code that is theirs to reshape (or asked you to build something
   new and keep building on it) → block **P**. Leave P out when the user wants the smallest possible change, and
   say in the recap that P was attached, because it also invites changes nobody asked for.
   GPT instead: multi-step Change → **O1**; Change that ends in deploy, publish, merge or an external write →
   **O2**; small or reversible code change → **O8**; a skill or `AGENTS.md` rule pulling against the request →
   **O3**; Writing → **O4** (+ **O5** when needed); Assessment → the "report findings, don't fix" sentence,
   plus **O6** for a non-technical reader; parallel work the user asked to split → **O7**.

**Claude: never attach blocks A, B, C, D, E, I, L, M, or N.** They are already active through the plugin hook (N only at
`xhigh`/`max`, where the hook adds it).
**GPT: at most three O-blocks per request**; if the same block keeps coming back, suggest moving it into
`AGENTS.md` in the recap. The improved
request stays short: four fields and only the conditional lines from item 6.

## Block texts
Copied word for word from `references/prompt-blocks.md`. Put the text itself in the block, never a `+ block`
label, except for J.

**F · Writing density** (short form):

```text
Please remove all mannered prose.
```

**G · Long outputs at xhigh or max effort**, at the end of the block. Replace `[max_tokens]` with
`CLAUDE_CODE_MAX_OUTPUT_TOKENS` when you know this session sets it; otherwise leave out ` of about [max_tokens] tokens`.

```text
Everything produced in one reply, including any reasoning or drafting done before the reply, counts toward a single limit of about [max_tokens] tokens. If that limit is reached before the reply is finished, the person receives a cut-off response and has to start over. Composing an entire output or deliverable in full as reasoning and then again as a reply would double the length of the turn without improving the result, so don't do that.

Instead, when the person has asked for a long or effort-intensive deliverable such as a multi-section document, a large table or dataset, or a complete code file, spend extra effort on understanding the request, checking the inputs the answer depends on, settling the structure and other difficult decisions, and otherwise using the reasoning space to reason and the output space to write an output. Usually it is not needed to draft an output multiple times.
```

**H · Search triggering at low effort** (on Sonnet 5.5 and Haiku 5.5, use their own search text from item 6 instead):

```text
When a query centers on a name you do not confidently recognize, or recognize from a fast-moving area like AI models and developer tools where the landscape shifts within months, the name itself is the thing to verify: search before answering, and include the name as the user wrote it in at least one query alongside any reformulations. This holds even when you have some background on it; partial background is exactly what makes an out-of-date answer sound authoritative, so familiarity is not a reason to skip the search.
```

**J · Quoting retrieved sources.** Write only the line `+ block J` in the block, then write the answer the way this
example does:

```text
<example>
<user>look up how the Riverton Ledger and the Coast Dispatch each covered the Harbor Bridge closure and compare their reporting</user>
<response>
[web_search: Harbor Bridge closure Riverton Ledger]
[web_search: Harbor Bridge closure Coast Dispatch]
Both outlets agree on the basics: the bridge closed on March 3 after inspectors found cracked welds, and the state expects repairs to take about eight months. Where they differ is emphasis. The Ledger treats it as a local-economy story. The Dispatch frames it as a funding failure; its editorial calls the closure "entirely foreseeable." Read together, the Ledger explains who is affected now and the Dispatch explains how it came to this; neither account alone gives the whole picture.
</response>
<rationale>CORRECT: The response is organized around where the two outlets agree and differ, not as a walk through either article. Each outlet's reporting is conveyed in one or two sentences of the assistant's own indirect speech. One short marked phrase from one source; every other claim is reworded. The response is still specific and complete.</rationale>
</example>
```

**P · Code ownership** (Fable 5.2 only; see item 6 for when):

```text
This codebase is yours: what it's for and how it's built are your call, and you'll keep building on it.
```

## Step 4 · Show, then run
Print the prompt in one fenced block titled `개선된 요청` (or `Improved request`), four fields only plus any conditional lines, then execute it as if
the user had sent it. The block opens your reply: print it in your first message, before any tool call, in
place of an opening line (only step 1's question may come first). Words written after a tool call often
reach the user only as a one-line summary, so a block printed later can be lost. Give brief updates while
you work, and close with a recap that stands on its own. End with exactly one status: DONE, DONE_WITH_CONCERNS, BLOCKED, or NEEDS_CONTEXT.

## Do not
- Do not widen the task while improving it. The rewrite clarifies; it does not add features.
- Do not turn an Assessment into a Change.
- Claude: do not add anti-formatting rules; the conditional formatting rule (block I) is already active.
- Do not attach block P to make a small fix "more thorough". It is for requests that ask for restructuring.
