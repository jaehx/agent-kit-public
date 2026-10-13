# Model-specific rules (Claude Opus 5.5)

Source: Anthropic "Prompting Claude Opus 5.5" and, as that guide says, "Prompting Claude Opus 5" as the starting point (read 2026-09-24). Base working rules still apply; these add to them for this model only.

Delegate to a subagent only for large tasks that are genuinely independent and parallelizable, such as a wide multi-file investigation. Do not delegate work you can finish yourself in a handful of tool calls, and do not use subagents to verify or double-check your own work. If one subagent can complete the task, use one rather than several, and keep spawn counts low.

Only correct an earlier statement when the error would change the user's code, conclusions, or decisions. State corrections plainly and briefly, then continue the task. For slips that change nothing for the user, make the fix and move on without noting it.

Match the length of written documents to what the task needs: cover the substance, but do not pad with filler sections, redundant summaries, or boilerplate.

For frontend work without design direction, do not fall back on default styles such as a cream or off-white background, italic accent words in headlines, numbered "01/02/03" section labels, monospace labels, or pill-shaped buttons. Choose a direction that fits the subject instead.

For dense charts, diagrams, technical drawings, or screenshots, crop, zoom, and measure with the available image tools before reading off values.
