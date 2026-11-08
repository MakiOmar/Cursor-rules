# Cursor rules library

A merged, deduplicated library of the rules from `cursorrules1/` (storefront project) and `cursorrules2/` (Credocode project), grouped into packs so a project only loads what applies to it.

## Install into a project

```powershell
.\install.ps1 -Target D:\Projects\my-app -Packs laravel,qwik,admin,public-site
```

`core` is always installed. `.\install.ps1 -List` shows every pack with its rule and skill counts. Existing files in the project are kept unless you pass `-Force`, and rules the library no longer has (renamed, moved, or removed) are reported so you can delete them. Rules land in `.cursor/rules/<pack>/`, skills in `.cursor/skills/`.

| Pack | Install when the project has… |
|------|-------------------------------|
| `core` | Always (router, docs sync, deploy safety, `new-project` skill) |
| `laravel` | A Laravel backend (includes feature flags, migrations, and the `deploy` skill) |
| `qwik` | A Qwik City frontend |
| `nuxt` | A Nuxt frontend |
| `admin` | An admin dashboard |
| `public-site` | Public, indexable pages |
| `cms-builder` | The Credocode visual builder / addon host |
| `wordpress` | A WordPress theme or plugin (its `**/*.php` glob suits WordPress-only repos) |

Don't install packs a project doesn't use: agent-requested rule descriptions are listed in every chat even when the rule body isn't loaded.

## How rules load (token cost)

| Trigger | Frontmatter | Cost |
|---------|-------------|------|
| Always | `alwaysApply: true` | Full body in every chat — only `core/00-router.mdc` (~1.4 KB) |
| Auto-attached | `globs: …` | Body loads only when a matching file is in context |
| Agent-requested | `description` only | Description in every chat; body loads when the agent decides it's relevant |
| Manual | none | Only when `@`-mentioned |

Before the merge, ~36 KB (~9,000 tokens) of always-on rules loaded in every chat. With every pack installed it is now the router (~350 tokens) plus the descriptions of 7 agent-requested rules (~200 tokens).

## Global User Rule

`global-user-rule.md` holds the cross-project rule to paste into **Cursor Settings → Rules → User Rules** (~1.3 KB instead of ~5.7 KB). It also maps where each section of the old User Rule moved. New-project requirements (stack, dashboard pages, roles, components) are the `new-project` skill, which asks for the frontend stack instead of assuming one.

## Project-specific rules

`templates/` holds fill-in templates (`.mdc.template`, so Cursor ignores them) for rules that only make sense per project: progress trackers, client parity logs, and shared UI controls. Copy one into the project's `.cursor/rules/project/`, replace the `{{placeholders}}`, and rename it to `.mdc`.

Fill in the `deploy` skill's **Project values** table in each project's copy. Hosts, users, and paths go there — never passwords, and never in this library.

## Adding rules, skills, and packs

Open this repository's root in Cursor: its `.cursor/rules/library.mdc` and `library-authoring` skill guide the agent through adding or changing content and keeping the router, this README, and the installer in sync. New pack folders are picked up by `install.ps1` automatically.

After every change run `.\validate.ps1`. It checks frontmatter and globs, unique skill names, `pack/name.mdc` references, IP addresses, that the router and this README list exactly the packs and skills on disk, and runs a test install of every pack. It exits with an error until everything is in sync.

## Where each original rule went

| Original (folder 1 / folder 2) | Library |
|--------------------------------|---------|
| `cursor-rules.mdc`, `cursor-rules.md`, `README.md` | `core/00-router.mdc` + this README |
| `documentation-updates` | `core/docs-sync` |
| `feature-modules` | `laravel/feature-flags` (addon lines → `cms-builder/addon-host`) |
| `deploy-via-git-only`, `deploy-credocode` | `core/deploy-safety` + `laravel` skill `deploy` (hosts removed) |
| `commit-before-new-task`, `commit-and-release-hygiene` | Replaced by the router's git line: commit, push, or deploy only when asked |
| `ajax` | Removed (empty file — frontmatter only) |
| `laravel-api-middleware` | `laravel/middleware` |
| `laravel-caching.md` + `laravel-caching.mdc` | `laravel/caching` |
| `laravel-config-not-env` | `laravel/config-not-env` |
| `laravel-form-requests`, `laravel-policies` | `laravel/requests-and-policies` |
| `eloquent-query-performance`, `request-memoization` | `laravel/query-performance` |
| `public-api-endpoints`, `http-cache-cdn` | `laravel/public-endpoints` |
| `laravel-rate-limits` | `laravel/rate-limits` |
| `security-uploads` | `laravel/uploads` |
| `queue-heavy-work` | `laravel/queues` |
| `multilingual-listings-no-fallback` | `laravel/locale-no-fallback` |
| `hardening-fix-workflow` | `laravel` skill `laravel-hardening` |
| `laravel-qwik-auth`, `website-api-client` | `qwik/auth-sanctum` |
| `qwik-route-actions` | `qwik/route-actions` |
| `qwik-minimal-chunks`, `no-render-blocking` | `qwik/performance` |
| `storefront-pending-feedback` | `qwik/pending-feedback` |
| `qwik-ssr-debug` | `qwik` skill `qwik-ssr-debug` |
| `admin-content-separate-pages`, `admin-content-language-title-slug` | `admin/crud-pages` |
| `admin-listings-bulk-actions`, `admin-row-actions-dropdown` | `admin/listings` |
| `admin-wysiwyg-textareas`, `wysiwyg-html-no-extra-entities` | `admin/rich-text` |
| `admin-native-select-dark`, `admin-checkbox-contrast` | `admin/native-controls` |
| `content-slugs-wordpress-style` | `admin/slugs` |
| `dashboard-no-search-index` | `admin/noindex` |
| `storefront-seo`, `frontend-detail-page-seo` (public part) | `public-site/seo-head` |
| `content-seo-fields`, `frontend-detail-page-seo` (model part) | `public-site/seo-content-model` |
| `self-hosted-icons` | `public-site/self-hosted-icons` |
| `storefront-email-obfuscation` | `public-site/contact-privacy` |
| `addon-host` | `cms-builder/addon-host` |
| `builder-dark-mode`, `builder-dynamic-tags`, `builder-import-export`, `builder-theme-documents` | `cms-builder/dark-mode`, `dynamic-tags`, `import-export`, `theme-documents` |
| `page-builder-widget-styles-tab`, `page-builder-layout-backgrounds` | `cms-builder/styles-and-backgrounds` |
| `grid-widget-columns`, `static-homepage` | `cms-builder/grid-columns`, `static-homepage` |
| `page-json-translation`, `theme-layout-json-translation` | `cms-builder` skill `builder-json-translation` |
| `storefront-progress-tracker`, `storefront-mobile-progress` | `templates/progress-tracker.mdc.template` |
| `storefront-mobile-port-log` | `templates/client-parity-log.mdc.template` |
| `storefront-quantity-stepper` | `templates/shared-ui-control.mdc.template` |
