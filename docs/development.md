# Development guide

**English** | [简体中文](development.zh.md) · [Documentation](README.md)

## Contribution path

Use a source checkout for contribution work; installation archives do not include the tests or contribution templates. Read [CONTRIBUTING.md](../CONTRIBUTING.md) (Chinese) before editing. Open or associate an upstream Issue, check for duplicates and define observable acceptance. External contributors fork; maintainers may use an issue-linked branch from current upstream `main`. Submit completed work through a PR with `Closes #number`, actual validation and untested scope.

External contributions receive maintainer review. For owner-initiated work implemented by Codex, Codex reviews the final changes, fixes findings, runs relevant checks and records a self-review before merging under the owner's authorization and repository protection rules. A self-review comment is not independent approval.

## Skill contract

Prefer extending an existing Skill. Add a Skill only when its responsibility and trigger boundary are distinct. The authoritative [authoring specification](authoring.md) (Chinese) defines required sections, native references, runnable examples, persistence/recovery and acceptance.

| Component | Required synchronization |
|---|---|
| `SKILL.md` | Name matches directory; precise trigger description; required workflow sections |
| `agents/openai.yaml` | Accurate UI boundary and a default prompt containing the Skill's `$name` |
| `references/native.md` and examples | Version-checked public APIs, complete execution and independently runnable examples |
| [tests/cases.json](../tests/cases.json) | Cases, conditions, expected results and capability IDs |
| [tests/routing/prompts.json](../tests/routing/prompts.json) | Positive, negative and adjacent-task prompts |
| [capabilities.json](capabilities.json) | Sources, example paths, test IDs and actual tested/untested scope |
| Root READMEs and [Skill catalog](skill-catalog.md) | Actual inventory and synchronized language navigation |

For API research, resolve Godot Engine through Context7 and query each concept separately; verify against matching official docs/source and actual public bindings. Research tools do not become runtime dependencies.

## Documentation changes

Keep English and Chinese topic pages paired, with reciprocal language links and a link back to the matching documentation home. Synchronize meanings, path names, counts and limitations. Preserve existing public paths when adding navigation. Historical reports retain their dates, recorded outcomes and original language; index them through [evidence](evidence.md) rather than rewriting their results.

Run [structure and link checks](testing.md) for documentation changes. Behavioral changes also need affected normal/negative cases; packaging changes need archive readback and relocation. Keep generated reports, downloads and caches out of Git. Local `AGENTS.md` remains untracked and excluded from distribution.

## Versions and delivery

When a release is in scope, synchronize all host manifests, marketplace metadata, changelog and both root READMEs, then perform the prescribed package checks. A documentation-only reorganization does not introduce a new runtime version. Do not claim unavailable schema checks, host routing, rendering or platform tests as completed. Exact commands and limitations belong in the PR.
