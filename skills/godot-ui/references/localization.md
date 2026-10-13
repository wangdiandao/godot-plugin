# Native localization: catalogs, runtime state and acceptance

Use this recipe when adding languages, diagnosing missing translations or validating runtime language changes. UI layout and font quality remain part of godot-ui; asset licensing/remaps may also need godot-assets. Preserve the project's existing key convention and catalog format.

## Author and persist

1. Inventory user-visible scene text, script `tr()`/`tr_n()` calls, dialog data, formatted strings and localized images/voices. Record source message, context, plural source, formatting contract and supported locales. Do not translate identifiers, paths or save keys.
2. Use CSV for simple tables when its importer fits the project; use native gettext PO for context/plural catalogs. Godot loads PO without a gettext tool runtime. The editor can generate POT from selected scenes/GDScript through Localization > Template Generation; do not invent a headless CLI extraction flag. For custom loaders/data, include their messages explicitly and document extraction coverage.
3. Register translation paths in `internationalization/locale/translations` and the fallback in `internationalization/locale/fallback`. Persist settings, import if the chosen format needs it and launch a fresh project process. `TranslationServer.add_translation()` alone is session state.
4. Test context-specific calls such as `tr("Open", "menu")`; plural choice belongs to the catalog language rules, not a hardcoded English `n != 1`. Preserve placeholders, markup and escaped literals using a format-aware contract. Audit each required message/context directly against the catalog because runtime fallback can hide missing entries.
5. Save user language preference separately under `user://`. Use `TranslationServer.set_locale()` when applying it, and handle `NOTIFICATION_TRANSLATION_CHANGED` for custom labels/cached presentation. Built-in Control automatic translation and explicit refresh must not double-translate a message.

Sources: [internationalization](https://docs.godotengine.org/en/4.7/tutorials/i18n/internationalizing_games.html), [gettext/POT](https://docs.godotengine.org/en/4.7/tutorials/i18n/localization_using_gettext.html), [Translation](https://docs.godotengine.org/en/4.7/classes/class_translation.html), [TranslationServer](https://docs.godotengine.org/en/4.7/classes/class_translationserver.html).

## Diagnose and prove the repair

| Observation | Ordered checks | Repair and retest |
|---|---|---|
| Source text despite a registered locale | Saved catalog paths -> native load result -> loaded locales -> exact key/context -> configured fallback | Repair the observed missing path/entry; restart and directly audit the catalog so fallback cannot conceal failure |
| Locale changes but a label stays stale | Actual locale -> automatic translation mode -> custom cached text -> translation-change notification | Fix the owning refresh path; switch A/B/A/B on the existing nodes without rebuilding the menu |
| Formatted text fails | Source and translated token names/counts -> escape syntax -> formatting method -> markup | Repair only the wrong token; preserve translator content and format with representative values |
| Plural or context is wrong | PO language/header -> plural forms -> message/context call -> quantities for that language | Repair the exact catalog/call; test singular and relevant plural forms, including zero where applicable |
| CJK boxes or RTL overflow | Packaged licensed fonts -> fallback coverage -> shaping/direction -> Container width | Render on the target device; lookup success does not establish glyph or layout quality |

Change a copied catalog for negative controls: remove a required entry and rename a placeholder, ensure both are detected, then repair the copy and verify the original hash/content stayed intact. Keep previous locale/settings for recovery; do not change the whole project's language merely to fix one panel.

## Pseudolocalization and visual acceptance

Use the project's pseudolocalization settings to expand/accent text and expose hardcoded strings. Runtime properties are reloaded with `TranslationServer.reload_pseudolocalization()`; toggle `pseudolocalization_enabled` for the check and restore it afterward. Built-in skip-placeholders behavior covers supported printf syntax; do not assume it understands arbitrary named-brace/markup formats. Pair format-contract checks with actual formatting.

Inspect longest strings at narrow/wide windows, supported scripts, focus traversal, IME and real target fonts. Fake BiDi/expanded text helps find problems but does not certify Arabic/CJK typography or accessibility. Preserve font licenses and disable/audit system fallback during packaged-font acceptance. [Pseudolocalization](https://docs.godotengine.org/en/4.7/tutorials/i18n/pseudolocalization.html).

## Standalone native example

Copy the complete [localization example](../assets/examples/localization/project.godot) to EXAMPLE. Create a fresh absolute OUT, then run:

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

The saved project configuration registers English/Spanish PO catalogs before the script starts. The example checks cold-start loading, uncached `.tres` readback, contexts/plurals, locale notifications, fallback, missing-entry/changed-token controls, repaired originals and pseudolocalization state. It writes `es.tres` and `result.json` and exits. Its token audit covers named brace tokens for its own two required keys; it is not a universal translation or format validator. No imported system font or third-party runtime is needed.

Matching implementation evidence: [Translation binding/storage](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/core/string/translation.cpp), [native PO loader](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/core/io/translation_loader_po.cpp). The baseline's native Translation supports contextual/plural storage; recheck actual public bindings on older engines instead of assuming older documentation or CSV import exposes the same contract.
