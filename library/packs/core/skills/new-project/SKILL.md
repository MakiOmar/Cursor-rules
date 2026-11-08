---
name: new-project
description: Set up a new project — stack choice, packs, roles, settings, and the standard admin dashboard. Use when starting a project from scratch.
---

# New project setup

Only for new projects. Existing projects keep their architecture; suggest a missing item from this list only when it matters for the current task.

## 1. Ask first (one question form, no defaults assumed)

- **Frontend / admin stack** — no default: offer Qwik City, Nuxt, or other.
- **Backend** — Laravel API unless the user says otherwise.
- Parts: public site, admin dashboard, visual builder (`cms-builder`)?
- UI languages at launch (at least one).

Then install the matching packs, e.g. `install.ps1 -Target <repo> -Packs laravel,qwik,admin,public-site`, and read the installed router.

## 2. Backend baseline

- Versioned API (`/v1`), Sanctum auth, named rate limiters (`laravel/rate-limits.mdc`, `laravel/middleware.mdc`).
- Roles **Super Admin**, **Admin**, **User** by default (adjust to the product). Authorize every route with policies; destructive abilities get their own permission (`laravel/requests-and-policies.mdc`). Admins can't edit or delete Super Admins.
- Multilingual is always on: enabled locales are a setting, not a feature flag, and a one-language site has one enabled locale (`laravel/feature-flags.mdc`, `laravel/locale-no-fallback.mdc`). Choose one storage for translatable DB content (JSON columns or translation tables) and document it.
- Settings: site metadata, languages, SMTP, cache tools. Store the SMTP password with an `encrypted` cast, fall back to env when empty, and never return it to the client (write-only field).
- Activity log for admin writes: actor, action, subject, changed fields, IP, time.
- Notifications on the database channel with read/unread state.

## 3. Dashboard pages

| Page | Contents | Access |
|------|----------|--------|
| Home | Stat cards, charts | Admin+ |
| Profile | Avatar, password, active sessions with revoke | Everyone |
| Users | List / create / edit pages, roles, bulk actions, export | Admin+ |
| Settings | Metadata, languages, SMTP (with test send), cache | Super Admin (or Admin, per product) |
| Activity logs | Filterable audit trail | Admin+ |
| Notifications | Read/unread, mark all read | Everyone |
| System health | Queues and failed jobs, storage, cache | Super Admin |

## 4. Data tables

Server-side pagination, search, sorting, and filters; bulk actions and row menus per `admin/listings.mdc`; export CSV/Excel/PDF honoring filters and selection, queued for large sets (`laravel/queues.mdc`).

## 5. Shared components (build once, reuse)

StatCard, DataTable, PageHeader, Breadcrumbs, NotificationBell, UserDropdown, ConfirmDialog (SweetAlert2), and FormModal for small sub-records only — create and edit are pages (`admin/crud-pages.mdc`). Feedback states per `admin/feedback-ui.mdc`.

## 6. Done when

- README setup steps, `.env.example`, and configuration doc are current (`core/docs-sync.mdc`).
- Feature tests cover login, role access per route group, and bulk endpoints.
- The admin is `noindex` (`admin/noindex.mdc`).
