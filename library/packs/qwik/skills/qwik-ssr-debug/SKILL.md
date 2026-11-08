---
name: qwik-ssr-debug
description: Debug Qwik City SSR — empty routeLoader$/routeAction$ data, wrong response shape, hydration differences. Use when SSR pages render empty or differ from client navigation.
---

# Qwik SSR debugging

`routeLoader$` and `routeAction$` run on the **server**: their `console.log` goes to the server terminal, not the browser. Browser logs only come from `useVisibleTask$` and event handlers. If you can't see server logs, surface state in the UI or a response header.

## Debug order

1. **Network path / base URL** — is the SSR fetch hitting the right host and path (server-side base URL differs from the browser's)?
2. **Response shape** — object vs string vs a client wrapper (`{ data: … }`); log `typeof` and top-level keys.
3. **SSR data wiring** — read `useX().value`, not a derived signal that is empty during SSR.
4. **Render conditions** — empty-state checks that hide real data.
5. **Hydration / client navigation** — compare a full reload with in-app navigation.

Don't touch caching or performance until steps 1–3 are confirmed.

## Temporary debug panel (local only)

When SSR data is unexpectedly empty, render a panel showing loader output lengths, response-shape metadata, the endpoint string, and which parse path ran:

```tsx
{import.meta.env.DEV && (
  <div class="mb-4 rounded border border-yellow-300 bg-yellow-50 p-3 text-xs text-gray-900">
    <div class="font-semibold">SSR Debug</div>
    <div>items length: {data.value.items?.length ?? 0}</div>
    <pre class="mt-2 max-h-64 overflow-auto whitespace-pre-wrap">
      {JSON.stringify(data.value.debug, null, 2)}
    </pre>
  </div>
)}
```

Alternatively set a debug response header from the loader (`headers.set('X-Debug-Shape', …)`) in development only.

## Rules

- Debug output is development-only (`import.meta.env.DEV`) and removed before the task is finished.
- Never print tokens, cookies, full API responses with user data, or other PII.
