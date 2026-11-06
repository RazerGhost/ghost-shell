---
name: brief
description: Turn a task into a brief (goal, context, constraints, done when) before any code is written.
disable-model-invocation: true
---
Write a brief for: $ARGUMENTS

Fill it in from the request and the repo; ask at most 1–3 questions for what you can't find.
- **Goal:** one sentence, the outcome rather than the steps.
- **Context:** the files and line ranges that matter, and the decisions or docs that apply.
- **Constraints:** what must not change, dependencies, public or private, deadlines.
- **Done when:** the checks that prove it (tests, a command, what to see in the app).
- **Out of scope:** what this task leaves alone.

Show the brief and wait for approval before starting.
