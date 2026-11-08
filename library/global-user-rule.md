# Global User Rule

Paste the block below into **Cursor Settings → Rules → User Rules**, replacing the old rule. It loads in every chat of every project, so it holds only cross-project essentials; framework, admin, and new-project specifics live in the packs and skills of this library.

```markdown
# Global rules (all projects)
Project rules in .cursor/rules and skills in .cursor/skills are more specific and win on conflict.

## Scope
- Match the project's stack, conventions, and pinned dependency versions. Ask before upgrades, new frameworks, structural or breaking changes.
- Change only what the task needs; no unrelated refactors.
- Commit, push, or deploy only when asked.

## Safety
- No secrets, credentials, or environment-specific values in code or commits.
- Destructive data operations need explicit confirmation and a backup; multi-step writes run in a transaction.
- Validate untrusted input at the boundary; parameterized queries only; escape output for its context and never double-escape stored data.
- Catch errors only to recover, clean up, or add context; otherwise let the framework handler report them. Never show internals to users.

## Quality
- Bug fixes and changed behavior get tests where a suite exists; fake third-party services, not your own code. Run them and never claim a pass you didn't run.
- Comments only for constraints the code can't show. No dead code or unused imports.

## Workflow
- Search the codebase before asking. Ask only when the answer isn't discoverable and a wrong guess is costly; otherwise proceed and state the assumption.
- Don't reprint code already applied via edits. Final report: outcome first, then key decisions, changed files, and verification results or blockers.
```

## Where the old rule's content went

| Old section | Now |
|-------------|-----|
| 1–7, 9–12, 14 (quality, security, data, errors, testing, scope, reporting) | Condensed into the block above |
| 4 (reversible migrations, FK indexes, soft deletes) | `laravel/migrations.mdc` |
| 8 Laravel | `laravel/requests-and-policies.mdc`, `laravel/query-performance.mdc` |
| 8 WordPress | `wordpress/standards.mdc` |
| 8 Vue/Nuxt | `nuxt/conventions.mdc` |
| 13 UI/UX (SweetAlert2, toasts, loading/empty states, mobile-first) | `admin/feedback-ui.mdc` |
| Part B (new-project stack, dashboard pages, roles, components) | `core` skill `new-project` (asks for the frontend stack; no default) |
| Part C (existing projects) | "Match the project's stack…" and "Ask before … structural changes" above |
