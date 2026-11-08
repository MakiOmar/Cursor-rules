---
name: library-authoring
description: Adds, changes, moves, or removes rules, skills, and packs in the rules library, keeping the router, README, and installer in sync. Use when the user asks for a new rule, skill, pack, or convention, or to change or reorganize existing ones.
---

# Library authoring

## 1. Pick the kind

| Need | Kind | Location |
|------|------|----------|
| Constraint while editing certain files | Glob rule | `packs/<pack>/rules/` |
| Constraint with no file pattern | Agent-requested rule (description only) | `packs/<pack>/rules/` |
| Multi-step procedure run occasionally (deploy, setup, debugging) | Skill | `packs/<pack>/skills/<name>/` |
| Content that only fits one project | Template | `templates/<name>.mdc.template` |
| Cross-project rule for every chat | Global User Rule (rare; keep it tiny) | `global-user-rule.md` |

## 2. Pick the pack

- Existing pack when the framework or area matches. `core` only if every project needs it.
- New pack only for a framework or area with its own file patterns (as `nuxt` and `wordpress` have). Check its globs don't fire on another pack's files when both are installed; if they would, note the limit in the README pack table.

## 3. Before writing

Search `library/` for the topic (Grep the key terms). If a rule already covers it, extend that rule instead.

## 4. Write it

Rule (`packs/<pack>/rules/<kebab-name>.mdc`):

```markdown
---
description: <Topic> — <key points, under 100 characters>
globs: **/path/**,**/other/*.ext
alwaysApply: false
---

# <Title>

- Imperative bullets with the concrete API, file, or value to use.
- Cross-reference related rules as `pack/name.mdc`.
```

For an agent-requested rule, drop the `globs` line and make the description name the task it applies to.

Skill (`packs/<pack>/skills/<name>/SKILL.md`, name matches the folder):

```markdown
---
name: <name>
description: <What it does, third person>. Use when <trigger scenarios>.
---

# <Title>

## Project values
| Value | Example |
|-------|---------|
| `{{host}}` | filled in by each project's copy, never in the library |

## Steps
1. ...
```

## 5. Sync points

| Change | Also update |
|--------|-------------|
| New or removed pack | Router pack table, README pack table, `install.ps1` `.EXAMPLE` lines |
| New, renamed, or removed skill | Router `Skills` line |
| New or removed agent-requested rule, or router edits | README token section (validate prints the numbers) |
| Moved or renamed rule | Every `pack/name.mdc` reference (Grep the old path), README mapping table, `global-user-rule.md` mapping |
| New install behavior (file kind or destination) | `install.ps1` code and its `.SYNOPSIS` |

## 6. Validate

```powershell
.\library\validate.ps1
```

Fix every `ERROR` and re-run until it prints `Library is valid.`. Treat warnings as review items. To see the result in a project, run `.\library\install.ps1 -List`, then `.\library\install.ps1 -Target <project> -Packs <pack>`.

## 7. Report

Say what was added or changed, the validate summary line, and, for renamed, moved, or removed rules, that existing projects keep the old copy until deleted (re-installing warns about it).
