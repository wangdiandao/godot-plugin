# Branching dialogue and input ownership

## Develop or modify

Use stable line IDs with text/translation keys, speaker and explicit next/choice edges. Validate graph shapes and all referenced IDs before opening or replacing a live conversation. Cycles can be intentional; add a progression/visited policy only when game rules need one. Keep authored dialogue content separate from presentation and quest/reward commands.

Use Container layout and RichTextLabel. Reveal text with visible_characters, allow confirm to reveal before advancing, and display/focus choices only when appropriate. Choose timers or delta accumulation according to pause/time-scale policy. On close/replacement, stop owned timers/tweens and detach old buttons; pending callbacks must not advance the next conversation. Route ui_accept/ui_cancel once, consuming UI input so the same key does not both choose a reply and trigger gameplay. Preserve game input bindings.

Grant rewards through an idempotent rule command keyed by quest/completion ID, not by counting UI close signals. Persist quest facts via godot-data and reapply initial UI state explicitly. Use [localization](localization.md) for translation lookup/font refresh; test actual CJK shaping separately from graph traversal. Stable dialogue IDs must not depend on translated display strings.

## Run and diagnose

Copy the complete example directory to a fresh workspace, create OUT, then run:

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Use absolute paths. Inspect the exit code, full error log and named `GODOT_PLUGIN_RESULT:` assertions together. Outputs belong to OUT; do not run fixtures against a player's real saves.

The [dialogue example](../assets/examples/dialogue/project.godot) tests graph validation, one-character reveal, skip-to-choice, actual ui_accept action dispatch to a focused Button, selected branch, completion once, malformed/dangling edges and repeated close/reopen. reveal_tick is manually driven for deterministic logic; the fixture does not claim a production timer, pointer interaction, text layout, CJK rendering or persistent quest reward validation. Use a real target scene for those concerns.

If a reply fires twice, trace input consumption, button lifetime and command deduplication independently. If a reopened screen advances by itself, inspect the old timer/request before altering next IDs. If keyboard selection fails, inspect visibility, enabled state and focus after the choices enter the tree.

Sources: [RichTextLabel](https://docs.godotengine.org/en/4.7/classes/class_richtextlabel.html), [Control input/focus](https://docs.godotengine.org/en/4.7/classes/class_control.html), [Input](https://docs.godotengine.org/en/4.7/classes/class_input.html). Community design: [UhiyamaLab dialogue](https://uhiyama-lab.com/en/notes/godot/dialogue-system/) (author's 4.7 note, 2026 update). The bundled implementation is original and contains no third-party artwork.

Version evidence: [Godot 4.7.2 source](https://github.com/godotengine/godot/tree/ed1daf0bf001b61586d9930840f2f1394092c079). Recheck the actual target binary. Community discussions supply use cases; official contracts and runtime checks determine supported behavior.
