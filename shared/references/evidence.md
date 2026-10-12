# Official Sources and Verification Evidence

Distinguish four facts for each capability: documented officially, publicly bound in the current version, successfully invoked, and verified target behavior. None automatically proves the other three.

Research records use pinned-version URLs: en/4.7 and 4.7.2-stable source for this release. The source release commit is ed1daf0bf001b61586d9930840f2f1394092c079. When sources disagree, record the original location and verify further against the actual version's source, bindings, and tests; do not infer old binary behavior from a newer stable page.

If Context7 is available in the authoring session, call resolve-library-id with the official name Godot Engine, then query-docs for a single question and check the official original sources. The published plugin has no dependency on this MCP.

See [capabilities.json](../../docs/capabilities.json) for the capability index. not_run means not executed; tested means the listed cases passed on the specified version/platform; conditional indicates environmental requirements; unsupported means no public capability under the constraints. If only API existence was checked, limit the recorded evidence to that fact.

Run reports include time, version, platform, renderer, command/case, logs, and artifacts. Negative cases must also check the expected error cause so arbitrary startup failures are not mistaken for expected rejection. The parent executor produces process lifecycle reports; a child script's success marker alone is insufficient.

Godot Engine's official source is MIT-licensed. This plugin provides links and original explanations; it does not bundle the complete engine source, release binaries, or large sections of official manuals. Test downloads remain in local artifacts and are excluded from release packages.
