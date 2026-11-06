---
name: review-diff
description: Review a diff for correctness, scope creep and missing tests.
disable-model-invocation: true
---
Review $ARGUMENTS (default: the uncommitted changes, else this branch against its base).

- **Correctness:** bugs, edge cases, error handling, validation at the boundaries.
- **Scope creep:** changes the task didn't ask for, unrelated refactors, new dependencies.
- **Tests:** new logic without a test, tests that don't exercise the change.
- **Repo rules:** anything against the repo's CLAUDE.md or engineering principles.

Findings most severe first, each with `file:line` and a one-line fix. No praise and no retelling of the diff; say so if nothing is found.
