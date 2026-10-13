# Prompt blocks from OpenAI's official guides (read 2026-09-26)

Use this file when the model running the skill is an OpenAI GPT model (Codex, ChatGPT). For Claude models use
`prompt-blocks.md` instead; never mix the two sets in one request.

Sources, all checked against the live pages on 2026-09-26:
- "Using GPT-6" (Model guidance, GPT-6 tab): https://developers.openai.com/api/docs/guides/latest-model
  Sections: Prompting best practices › Initiative and follow-through · Instruction following · Personality and
  writing style · Subagent delegation · Testing and verification. The page says its prompts "address behavior
  observed with GPT-6 Astra; evaluate them with your chosen model and workload."
- "Best practices" (Codex): https://learn.chatgpt.com/guides/best-practices
- "Custom instructions with AGENTS.md": https://learn.chatgpt.com/docs/agent-configuration/agents-md
- "Prompt engineering": https://developers.openai.com/api/docs/guides/prompt-engineering
- "Codex Prompting Guide" (Cookbook, Feb 25, 2026, written for gpt-5.3-codex):
  https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide

Copy blocks verbatim. The older XML-tag snippets (`<persistence>`, `<tool_preambles>`, ...) come from the GPT-5
and GPT-5.2 Cookbook guides, which OpenAI now marks archived; do not use them for GPT-6.

## Request shape (Codex "Best practices")

The guide's default prompt has the same four fields as this skill: **Goal**, **Context** (files, folders, docs,
examples, errors; `@` mention files), **Constraints** (standards, architecture, safety requirements,
conventions), **Done when** (tests passing, behavior changing, a bug no longer reproducing). "This helps Codex
stay scoped, make fewer assumptions, and produce work that's easier to review."

Known GPT-6 Astra tendencies these blocks target (Model guidance): more likely to ask the user a question and
stop when you expect it to assume and persist; more sensitive to instructions in skills and `AGENTS.md`; leans
toward detailed, formatted responses and recurring phrases; may delegate to subagents less than desired; tends
to over-test small coding tasks.

## O1 · Bias towards action (Change tasks that take more than a few steps)

```text
You should infer the user's intent and task scope from the instructions and prior conversation context. Your job is to bias towards action and carry the user's intended task to completion.

When the user expresses intent to perform new work or fix an existing issue, persist until the user's intended goal is complete. Progress autonomously towards the user's goal (e.g. creating isolated worktrees / checkouts if needed, resolving merge conflicts, read-only actions, creating draft PRs etc.) unless they are clearly destructive or irreversible.
```

## O2 · Approval only after a reviewable result (Change tasks that end in deploy, publish, merge, or an external write)

```text
Before asking the user clarifying questions, you should complete the work that is already authorized from context and necessary to make the proposed action concrete and reviewable. The user should be approving a concrete, reviewable result. For example, before deploying a change, writing to an external application, merging a PR or publishing a site, do all the required work first so that user approval is the final step. You don't need user permission for reversible tasks, read-only actions, reviews or fixes, or anything for which authorization is provided earlier in the session or strongly implied from the task instruction.

Do not introduce unsolicited warnings, disclaimers, approval flows, or safety/compliance checklists due to hypothetical risk.
```

## O3 · User instructions over skills (when a loaded skill or AGENTS.md rule pulls against the request)

```text
The user's instructions take precedence over guidelines provided in a skill. If explicit user instructions conflict with a skill's instructions, prioritize the user's instructions.

If a skill causes you to ask for permission or confirmation, pause, leave requested work unfinished, or diverge from the user's intent, name and link to the exact SKILL.md file you read, quote the relevant instruction, and briefly explain how it applies. Distinguish explicit skill requirements from your interpretation of guidelines.
```

## O4 · Prose with less formatting (Writing tasks, or when the user wants prose)

```text
Default to using clear, concise paragraphs, each developing one main idea. Use lists only when the information is genuinely parallel, sequential, or easier to compare, and avoid nested lists unless the hierarchy cannot be expressed clearly in prose. Use plain, simple language: familiar words, concrete examples, and precise verbs. Prefer active voice and direct statements.

Make sure to state the main point clearly and early, then develop it with the explanation and detail the reader needs. Let each sentence build on what came before. Develop the points that matter and provide enough support to be useful.
```

## O5 · Reduce jargon and stock phrases (Writing tasks; add after O4 when the draft reads canned)

```text
Avoid using slop words or phrases like "Bottom Line:" in conclusions, "delve," "foster," "leverage," "it's worth noting," "importantly," "Question? Answer." or "This isn't about X. It's about Y.", "genuinely" or hyphenated compound descriptions and adjectives. Do not use concluding summary statements such as "In short:..", "The simplest mental model is:...".

State the intended action directly. Avoid adding what you won't do, what will remain unchanged, or how you'll separate or categorize results. Do not use contrastive framing such as "X, not Y" or "X—not Y" that introduces an unprompted alternative that the user didn't ask about. Avoid invented compound labels like "exact-head checks" and "editorial-row layouts", vague qualifiers, and canned transitions; use plain verbs and prepositions to state the actual relationship directly.
```

## O6 · Technical communication (Assessment or explanation for a reader outside the code)

```text
Use plain language over jargon, and reference technical details only to the degree that it helps illustrate an idea or your work to the user. Communicate complex concepts in a clear and cohesive manner, and calibrate your writing to the level of background knowledge assumed from the user's prompt and context.
```

## O7 · Delegate parallel work (only when the user asked for subagents or the task splits into independent parts)

```text
If at any point you can parallelize work by delegating tasks to another agent (no matter if you are the root or subagent), you should do so using collaboration tools if it could save time or improve quality.
```

## O8 · Calibrate testing (small or reversible code changes)

```text
Do not write tests for reversible, low-impact changes that mirror the implementation. If you do choose to verify your work with tests, make sure that the tests are meaningful and necessary to verify implementation.

Run tests appropriate to the change and complete required checks. Once those pass, broaden or repeat testing only when new changes, failures, or unresolved concerns justify it; otherwise, continue toward completing the task.
```

Skip O8 when the user's AGENTS.md or request requires tests for every change; the user's rule wins (O3).

## Reasoning effort (a setting, not a request line)

- Codex "Best practices": "Start with Medium for GPT-6 Sol, High for GPT-6 Luna, or Light for GPT-6 Astra (low
  in configuration)." Low for well-scoped tasks, Medium or High for complex changes or debugging, Extra High for
  long, agentic, reasoning-heavy tasks.
- GPT-6 Astra does not support `none`; use `low`. In Codex set it with `/model` or `model_reasoning_effort` in
  `~/.codex/config.toml`. Writing an effort line into the request changes nothing.

## Durable rules belong in AGENTS.md, not the request

Codex "Best practices" lists "Overloading the prompt with durable rules instead of moving them into AGENTS.md or a
skill" as a common mistake. If a rewrite keeps needing the same block, suggest adding it to `~/.codex/AGENTS.md`
(global) or the project's `AGENTS.md` in the closing recap instead of attaching it every time. Codex reads the
global file, then one file per directory from the project root down to the working directory; later files
override earlier ones, and the combined size is capped by `project_doc_max_bytes` (32 KiB default).
