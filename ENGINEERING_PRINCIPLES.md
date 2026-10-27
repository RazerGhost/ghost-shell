# Engineering principles

These rules apply to every change in this repo. They sit on top of the project's own conventions in CLAUDE.md; when the two disagree, the project conventions win.

## Before changing code

- **Chesterton's Fence.** Don't remove or replace code until you know why it's there. Read the code the change touches and the code that calls it, and trace the real flow before choosing a solution.
- **Principle of Least Astonishment.** Follow the patterns, naming and structure already used in this repo. New code should look like it was written by the same person as the code around it.

## Scope

- **YAGNI (You Aren't Gonna Need It).** Build what the task needs now. No options, hooks, abstractions or config "for later".
- **KISS (Keep It Simple).** Prefer the simplest solution that fully solves the problem. Readable beats clever.
- **Not Invented Here (avoid it).** Before writing something, check in this order: existing code in the repo, the language's standard library, platform features (Web APIs, native HTML), installed dependencies. Write new code only when none of these fit.
- **Small batches.** One concern per change. Don't refactor unrelated code in the same change; mention it in the summary instead.

## Structure

- **DRY (Don't Repeat Yourself), with the Rule of Three.** Don't duplicate knowledge that already exists in the repo. But don't extract a shared abstraction until the same thing appears a third time; two similar pieces of code are cheaper than the wrong abstraction.
- **Single Responsibility.** A function, module or component does one thing. If describing it needs "and", consider splitting it.
- **Separation of Concerns.** Keep data access, business logic and presentation in their own layers, following the boundaries this repo already has.
- **Composition over Inheritance.** Prefer small functions and composables over class hierarchies and base classes.

## Safety

- **Validate at the boundaries.** Treat everything from outside (requests, forms, files, env vars, third-party APIs, plugins) as untrusted. Validate and type it where it enters; trust it inside.
- **Fail Fast.** Detect invalid state early and fail loudly with a clear error. Never swallow errors silently or return fake defaults to hide them.
- **Least Privilege.** Code, users and plugins get only the permissions they need. Never widen access to make something work.
- **Defense in Depth.** Security checks are not skipped because another layer "probably" handles it. Keep authorization, escaping, parameterized queries and rate limits where they apply.
- **Type safety.** No `any`, no unchecked casts, no disabling the type checker or linter to make an error go away.
- **Accessibility** is a requirement, not a nice-to-have.

## Performance

- **Avoid premature optimization.** Make it work, make it right, then make it fast, and only optimize with a measured reason. Do not introduce obviously slow patterns either (N+1 queries, unbounded loops over user data, missing pagination).

## Dependencies

- **Dependency hygiene.** No new dependency without asking first. Name the package, why it's needed, its licence and maintenance status, and what the alternative without it would be.

## Done

**Definition of Done.** A change is done when:

- New logic with a branch, loop, parser, money, dates or permissions has at least one focused test (prefer extending an existing test file)
- The project's checks pass (typecheck, lint, tests). If a check can't be run, say which and why
- Docs are updated if behaviour or public API changed

**Boy Scout Rule, scoped.** Leave the code you touched slightly cleaner than you found it, but only within the files and lines the change already touches.

End every change with a short summary: what changed, what was reused instead of written, and anything skipped, deferred or unverified that the reviewer should know about. Deferred work goes in this summary or an issue, not as comments in the code.
