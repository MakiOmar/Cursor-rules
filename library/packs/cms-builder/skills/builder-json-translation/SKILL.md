---
name: builder-json-translation
description: Create, edit, or translate builder export JSON (page exports and Theme Builder layout exports). Use when asked to create a page import file, translate, localize, complete languages, or edit such a file.
---

# Builder export JSON: create / edit / translate

Two formats exist; check `format` first:

| Format | Content | Project doc |
|--------|---------|-------------|
| `credocode.content-export` (entity `pages`) | CMS pages with page `translations` rows and block settings | `docs/PAGE_TRANSLATION_AGENT.md` |
| `credocode.chrome-layouts-export` / `credocode.builder-export` (header, footer, body, single, archive, loop_item, overlay) | Theme Builder layouts | `docs/THEME_LAYOUT_TRANSLATION_AGENT.md` |

Read the project doc for the format before touching the file: it defines the output contract and the translatable keys per block type.

## Creating a new page import file

Never hand-write the JSON or a one-off script. Use the project's page-import tool (e.g. `tools/page-import/`):

1. Add a spec (copy an existing one), writing each string once with `t(en, ar)` and icons with `icon('lucide:…')`.
2. Build with `--validate` and fix every `LOST` / `DROPPED` line until it reports OK.
3. Hand over the generated file; commit the spec, not the output.
4. Extend the tool's shared builder library when a new widget needs it instead of working around it in a spec.

## Editing or translating

- Confirm the **primary** and **target** languages if the request doesn't state them.
- Change only text: keep ids, structure, media ids, icons/SVG, URLs, styles, `[[ ]]`, `{{ }}`, and HTML tags intact.
- **Pages:** never write a page `translations` row with title, subtitle, and excerpt all empty (it deletes that language).
- **Layouts:** translate only block text under `document.sections` via `settings.translations.<locale>`; never change `format`, `kind`/`builder`, item `name`, `slug`, `status`, `document_version`, or `document.overlay` (import upserts by slug). Don't translate menu links or global widgets (`global_id`). Templates (conditions only) have no text.
- Write the result as a new file next to the original (`…-translated.json`) unless told to overwrite.
- For large files, edit programmatically over the parsed JSON so nothing outside text changes; delete the temp script afterwards.
- Validate that the result parses (`ConvertFrom-Json` / `JSON.parse`) and report the counts of pages/layouts and blocks translated.

When translatable widget fields change, regenerate the translatable-keys table in the project doc from the widget/kit registries.
