# UI recipes and diagnostics (Godot 4.7)

Choose: new menu/HUD, existing Theme change, focus/input failure, resolution overflow, localized text or text-entry failure. API baseline is [Control](https://docs.godotengine.org/en/4.7/classes/class_control.html), [Theme](https://docs.godotengine.org/en/4.7/classes/class_theme.html), [LineEdit](https://docs.godotengine.org/en/4.7/classes/class_lineedit.html) and locally tested Godot 4.7.2. Research retrieval is not a runtime dependency.

## Isolated executable acceptance

Copy `assets/examples/minimal/` to a clean directory; create OUT and run:

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Outputs: `menu_theme.tres`, `menu.tscn`, `result.json`, engine log. The example supplies inherited Button font/size/color/StyleBox, assigns owners, saves/reloads with CACHE_MODE_IGNORE, verifies a persisted local override and its removal, then dispatches press/release to a focused Button, checks Container layout and Chinese translation lookup. The SystemFont uses local fallback only; this is not a packaged CJK font or proof of rendered glyphs. Run without headless and inspect target resolutions to validate actual appearance.

## Develop a pause menu or HUD

1. Inspect project input actions and logical base resolution. Choose canvas_items scaling for crisp scalable UI, or viewport/integer scaling when deliberate pixel-art scaling requires it. Set an aspect policy and minimum window size; do not change project-wide scaling when the request concerns only one panel.
2. Create a screen root Control with full-rect anchors. A pause menu typically uses MarginContainer → VBoxContainer → Label/Button rows; a HUD uses anchored panels around a flow-based interior. Containers own children offsets and size, so express minimums and size_flags rather than resetting positions each frame.
3. Set the menu root process_mode to PROCESS_MODE_WHEN_PAUSED when it must operate while the tree is paused. Its initial visible state, opening/closing policy, focus restoration and pause ownership must be explicit; one menu should not unpause a game paused by another system.
4. Give buttons semantic text, accessible names where necessary and visible focus styles. On opening, show then call_deferred("grab_focus") on a visible enabled button. Define focus_neighbor_* when automatic geometric order is ambiguous. Preserve built-in ui_accept/ui_cancel actions while modifying their events.
5. Connect actions to real game behavior and test input. A focused Button should receive both press and release; pressed.emit only verifies the callback. Use Input.parse_input_event or Viewport.push_input for replay checks, then actually test mouse and gamepad navigation.
6. Save a PackedScene with generated child owner set to its scene root; save its Theme and translations. Reload CACHE_MODE_IGNORE, instantiate and repeat interaction. Test pause/unpause, opening twice, hidden/disabled focus, narrow/wide windows and long text.

Example menu lifecycle (attach to a panel in an actual scene):

```gdscript
extends Control
@onready var resume: Button = $Margin/VBox/Resume
var previous_focus: Control
func open_menu() -> void:
    previous_focus = get_viewport().gui_get_focus_owner()
    show()
    get_tree().paused = true
    resume.call_deferred("grab_focus")
func close_menu() -> void:
    hide()
    get_tree().paused = false # Only if this menu owns the pause.
    if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree():
        previous_focus.call_deferred("grab_focus")
```

Set pause processing in the scene so close_menu can run while paused. Do not use this unpause line for shared pause ownership without adapting it. [Containers](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_containers.html), [multiple resolutions](https://docs.godotengine.org/en/4.7/tutorials/rendering/multiple_resolutions.html), [pausing](https://docs.godotengine.org/en/4.7/tutorials/scripting/pausing_games.html).

## Modify a shared Theme without unexpected global changes

Find the effective scope: local overrides, theme_type_variation, nearest Control Theme and project Theme. Theme inheritance needs an uninterrupted Control chain. Inspect explicit items; fallback getters can return plausible fonts/colors even when the intended item was never saved. `Theme.add_type` empty types are not persisted, and has_font/has_font_size can be true because defaults exist.

For a shared theme edit, modify the intended saved Theme. For a single Button exception, duplicate the StyleBox so another control is not changed:

```gdscript
var local_style := button.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
if local_style == null:
    push_error("Expected StyleBoxFlat; choose the existing style type")
    return
local_style.border_width_bottom = 2
local_style.border_color = Color(0.2, 0.8, 0.4)
button.add_theme_stylebox_override("normal", local_style)
```

Create shared fonts with Theme.set_font("font", "Button", font), sizes with set_font_size and states with set_stylebox("normal"/"hover"/"pressed"/"focus", "Button", style). A custom type variation uses set_type_variation("DangerButton", "Button") plus button.theme_type_variation. Avoid renaming variation bases to empty/built-in type names: reversing the name alone does not restore lost connections. Theme.merge_with mutates the receiver and later values win; merge into a new Theme when preserving both originals.

Save Theme and scene with checked ResourceSaver results; reread CACHE_MODE_IGNORE and assert the child's effective items. Remove local overrides and assert inheritance restores. Inspect normal/hover/pressed/disabled/focus rendering, font glyphs and content margins at target sizes. [Theme editor](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_using_theme_editor.html).

## Localization, font and rich-text recipe

For catalog authoring, runtime refresh, missing-key/placeholder diagnosis and standalone native checks, read [localization.md](localization.md). The minimal menu's lookup is only a smoke check.

Choose stable semantic message IDs or source text, extract messages and retain interpolation placeholders/plurals. Use TranslationServer.add_translation and set_locale for runtime switching; persist locale preferences separately in checked ConfigFile. Signal translation change to update text, including text assembled from data. A lookup assertion is independent from visual text shaping.

Package fonts whose licenses permit redistribution; do not redistribute discovered system fonts by assumption. Configure a project font/fallback stack with actual glyph coverage. Disable or audit system fallback during acceptance so the development machine does not hide missing glyphs. Test mixed Latin/CJK/Arabic, combining marks, emoji, numbers, RTL reading order and long strings. Text language controls breaking/shaping; direction controls BiDi. Locale syntax includes optional Hans/Hant script and country fields, not only language_country.

For small UI fonts, compare raster hinting/oversampling to MSDF rather than always choosing MSDF. MSDF loses hinting and can mishandle overlapping contours; its pixel range must be at least twice the largest outline. FontFile oversampling, viewport effective oversampling and draw-call overrides are distinct. Changing font cache glyphs does not automatically free texture pages. [FontFile](https://docs.godotengine.org/en/4.7/classes/class_fontfile.html), [internationalization](https://docs.godotengine.org/en/4.7/tutorials/i18n/internationalizing_games.html).

RichTextLabel text assignment rebuilds its tag stack. append_text avoids reparsing the whole document but cannot close tags opened in a previous append call; add_text inserts raw text without interpreting user BBCode. Keep push/pop balanced. Wrapped fit_content requires a maximum width. Threaded is_finished/finished means processing completed, while visible bounds and scrolling still require a draw. Visible character counts use codepoints, not graphemes or C# UTF-16 units. Validate meta_clicked URL/action payloads before opening anything. Provide image alt text and table/column names for assistive apps. [RichTextLabel](https://docs.godotengine.org/en/4.7/classes/class_richtextlabel.html).

## Text-entry modification and failure checks

LineEdit focus is distinct from editing: arrow navigation can focus without editing; Tab/grab_focus still enters edit mode. Use editing_toggled and keep_editing_on_text_submit according to product flow. Assigning text does not emit text_changed, so explicitly update validation/model state for programmatic changes. Placeholder is not a default value.

Validate text independently of virtual keyboard type. max_length can truncate pasted/existing contents and emit text_change_rejected; retain rejected-input feedback. Test IME composition commit/cancel and grapheme-aware deletion. `secret` masks display while underlying text remains plaintext; avoid logging it. Keyboard password mode is unsupported on Web. Disable middle-mouse paste only where supported, and do not assume shortcut_keys_enabled disables caret movement.

## Diagnosis: symptom → check → cause → fix → retest

| Symptom | Check | Cause and fix | Retest |
|---|---|---|---|
| Click never reaches button | Overlay mouse_filter, visibility, disabled, pause processing | Blocking Control or inactive branch; fix filter/process mode or hierarchy | Real pointer and press/release, paused and running |
| Keyboard navigation jumps | Initial focus, hidden controls, neighbor paths | Ambiguous focus graph; explicit valid neighbors, restore focus after panel close | Full keyboard/gamepad loop in both locales |
| Theme change does nothing | Overrides, variation, Control chain, explicit saved item | Local override/fallback masks shared Theme; change correct scope or remove override | CACHE_IGNORE reload and effective item lookup |
| Text overflows | Container constraints, maximum width, stretch policy | Width is unconstrained or parent manages offsets; set size limits/flow | Narrow/wide windows and longest localized string |
| Chinese shows boxes | Packaged fallback glyphs, system fallback, font source | Missing glyphs; add licensed coverage and reimport | Actual rendered glyphs on clean target device |
| Typed text differs from model | Programmatic setter, IME, validation signal | text setter does not emit change; explicit sync and composition handling | Paste, set_text, IME, undo and submit |
| Rich text metrics wrong | threaded completion and first draw | Partial shaping or undrawn geometry; await correct boundary | Actual visible bounds and scrolling, not only finished |

## Acceptance boundaries

### Repair pointer interception

1. Reproduce a real pointer press/release at the button's viewport coordinates; record root/SubViewport size, pause state and whether the button is disabled. Keyboard success does not prove pointer reachability.
2. Inspect Controls above the button, their visible rectangles and `mouse_filter`. A transparent overlay can still receive input. Keep modal blockers intentional; do not change every Control to IGNORE.
3. Change only the unintended interceptor. Repeat pointer activation twice and check that style, geometry and keyboard focus remain intact.
4. Retest an intentional modal blocker. If input still fails, inspect coordinate transforms and event handling before changing hierarchy or scene-wide pause policy.

The menu fixture exercises STOP -> IGNORE -> repeated activation -> STOP, preserving button style and overlay size. Headless dispatch establishes event behavior; real viewport composition and physical pointer interaction need rendered acceptance.

Input dispatch, resource persistence and translation lookup are independently testable headlessly. Layout screenshots, CJK shaping, pointer coordinates in Viewports, screen readers and virtual keyboards require their actual environment. AccessibilityServer.is_supported is not proof that assistive processing is active; test semantic labels/actions and keyboard operation with a screen reader. [AccessibilityServer](https://docs.godotengine.org/en/4.7/classes/class_accessibilityserver.html) are on-demand low-level references; Nodes already own their accessibility elements.


The pointer diagnostic in the example deliberately adds a STOP overlay, verifies that it blocks button activation, changes it to IGNORE and verifies actual pointer activation. The headless root must have a defined 320×180 viewport: its default 64×64 area excluded the button center during an initial failed replay. The example now defines that size and notifies headless mouse entry once. This is part of the test setup; a successful keyboard dispatch alone never proves pointer accessibility.


Binding reference: [fixed4.7.2 implementation](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/scene/gui/control.cpp). Internal methods are not public API evidence unless bound and verified in the task environment.
