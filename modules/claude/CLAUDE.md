# Working with Dimitri (every project)

Personal rules for all repos. A repo's own CLAUDE.md and engineering principles win where they differ.

## Before starting
- If the task or its "done" is unclear, ask 1–3 targeted questions before writing code.
- Work over ~30 minutes or across several modules: write a short plan first and wait for approval.
- If something is faster by hand (a rename, a one-liner), say so instead of doing it at length.

## Model routing
- Boilerplate, formatting, simple tests, summaries: the smallest capable model (Haiku subagents). For private client code, suggest the local model (Ollama, ghost-shell's `llm` module).
- Normal features and debugging: Sonnet. Architecture, hard bugs, cross-cutting refactors, reviews: Opus.
- Start one tier lower and escalate only after it fails. If this session's model is wrong for the task, say so.

## Context
- One task per session. Suggest `/clear` or a new session when the topic changes, and compacting when a session runs long or drifts.
- Read only the files and line ranges needed; never whole directories or full logs.
- Broad searches go to a subagent that returns conclusions, not file dumps.

## Stop rules
- Three strikes: after 3 failed attempts at the same thing, stop, summarize what was tried and ask. Don't retry harder.
- Every autonomous loop needs an exit condition: tests pass, a maximum number of iterations or a maximum diff size.

## Output
- Small, single-concern diffs; nothing that wasn't asked for. Run the relevant tests, lint and typecheck before calling it done.
- Commit or push only when asked.
- End with what changed and what to verify, not a step-by-step recap.

## Reuse
- If I explain the same thing twice, propose adding it here, to the repo's CLAUDE.md, or as a skill.
- Record decisions in the repo (decision records, docs) instead of re-deriving them.
