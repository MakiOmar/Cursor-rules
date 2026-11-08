---
name: laravel-hardening
description: Audit and fix performance/security problems across a Laravel app — scope, order, regression tests, commits. Use when asked to harden, audit, optimize, or fix load or security issues.
---

# Laravel hardening workflow

The concepts live in focused rules; this skill says how to apply them across the codebase.

| Concern | Rule |
|---------|------|
| Cache keys, null results, stampedes, version bumps, dependencies | `laravel/caching.mdc` |
| Public endpoint inputs, published-only data, Cache-Control / CDN | `laravel/public-endpoints.mdc` |
| N+1 (incl. hidden in helpers), batching, schema checks, per-request memo | `laravel/query-performance.mdc` |
| Limiters, trusted proxies, real client IP | `laravel/rate-limits.mdc` |
| Global middleware stack | `laravel/middleware.mdc` |
| Uploads and SVG | `laravel/uploads.mdc` |

## Order of work

1. **Find every instance, not just the reported file.** Search the whole backend for the pattern (`Cache::remember`, settings loaders, `Schema::hasTable`, `->get()` without a limit, `where('slug'`) and list affected files before editing.
2. **Fix shared helpers first** (settings memo, sentinel/key helpers, version bump), then their callers.
3. **One concern per commit**, e.g. "memoize settings", "cache 404 sentinel for public endpoints". Don't mix in unrelated refactors. Commit only when the user asks.
4. If the backend is a git submodule, commit inside the submodule, then bump the pointer in the parent repo.

## Every fix must

- Ship a regression test that fails before the fix: query counts (`expectsDatabaseQueryCount`), response JSON (no draft data), headers (`assertHeader('Cache-Control', …)`), cache entries.
- Keep the API response shape unchanged unless the change *is* the fix; otherwise update the API reference.
- Update `.env.example` and the configuration doc for any new config (`core/docs-sync.mdc`).
- Pass `php artisan test` (and the frontend test suite when shared contracts change).

## Behavior changes need a heads-up

Restoring default global middleware (`TrimStrings`, `ConvertEmptyStringsToNull`, maintenance mode), lowering `stale-while-revalidate`, or tightening limits changes runtime behavior. Call it out in the summary and ask before shipping when the impact is unclear.
