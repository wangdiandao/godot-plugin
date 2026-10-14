# Contributing

**English** | [简体中文](CONTRIBUTING.zh.md)

## Workflow and responsibilities

Open or associate an Issue in the [upstream repository](https://github.com/wangdiandao/godot-plugin/issues) before editing anything, including documentation, fixes, new skills, and releases. Search for duplicates first. Each Issue should have one clear goal; avoid unrelated changes. The initial import of `main` and `v0.1.0` is the only initialization exception.

1. Use the Issue template to describe the problem, scope, and observable acceptance criteria. For a new skill, first explain why existing skills cannot cover its responsibility.
2. External contributors fork the upstream repository and configure upstream; maintainers may develop directly on repository branches.
3. Create `type/<issue-number>-<summary>` from the latest upstream `main`, for example `docs/1-contribution-workflow`. Do not push directly to `main`.
4. Complete the implementation, examples, and relevant validation before submitting a PR. Use a Draft PR for unfinished work.
5. Link the Issue with `Closes #<number>` in the PR and include execution evidence, untested scope, and compatibility impact.
6. Address review findings and update evidence. Maintainers review external contributions. For owner-initiated PRs implemented by Codex, Codex reviews the final changes, addresses findings, and records the result without waiting for additional human review. If GitHub prevents authors from approving their own PRs, record the self-review in a review comment; do not claim independent approval. Merging must comply with the owner's authorization and repository protection rules.

Use commit subjects in the form `type: imperative summary (#issue)`, for example `fix: detect import errors (#12)`. Supported types are `feat`, `fix`, `docs`, `test`, and `chore`. This is a newly established convention, not an inference from historical commits.

## Issue standards

Summarize the action or failure in the title. Include the problem and user goal, type, affected paths/skills, scope and non-goals, current and expected behavior, reproduction steps, Godot/Codex versions and platform, acceptance checklist, and validation plan in the body. For failures, attach a minimal project and logs; for new capabilities, include official sources and runtime requirements. Explicitly mark unknown conditions as unknown. Do not submit credentials, personal paths, or private resources from user projects.

## Creating and modifying skills

Read the [authoring specification](docs/authoring.md) first and prefer extending existing skills. A new skill must have an independent responsibility and clear boundaries for positive triggers, non-goals, and adjacent requests.

```text
skills/godot-<domain>/
  SKILL.md
  agents/openai.yaml
  references/native.md
  assets/examples/minimal/
    project.godot
    example.gd
```

Add `scripts/` only when repeated, domain-specific operations require it. Put general tools in `shared/scripts/`. Do not create empty directories or introduce default runtime dependencies.

`SKILL.md` must contain frontmatter with `name` and a trigger `description`. The name must match the directory, and the following validator-required sections must remain:

- `Purpose and Scope`
- `Prerequisite Checks`
- `Workflow and Key Decisions`
- `File Changes, Saving, and Recovery`
- `Acceptance and Delivery`
- `On-Demand References and Examples`

The entry document explains decisions, saving, failure recovery, and acceptance. Put detailed APIs and complete commands in `references/native.md`. The default prompt in `agents/openai.yaml` includes `$skill-name`, and UI descriptions reflect the actual boundaries. Minimal examples must run when copied to a clean directory, accept an output directory, emit explicit results, and exit.

Update `tests/cases.json`, `tests/routing/prompts.json`, and `docs/capabilities.json` together. When adding a skill, also check the actual directory inventory, case/capability references, and README inventory checked by `tests/validate_structure.py`; fixed-count assertions are no longer used. Deletions or renames must explain compatibility impact and update all references. Research interfaces with Context7, then verify version-matched official documentation, source bindings, and a minimal call. Research tools must not become plugin runtime dependencies.

## Validation and review requirements

See [authoring.md](docs/authoring.md) for commands. Maintenance structure checks require Python and PyYAML; schema validation also requires jsonschema and the corresponding schema. The schema is currently in an ignored research directory, so do not claim that this check has run in a clean checkout.

- Every PR must pass structure checks and check Markdown links and inventory consistency.
- Behavior changes run affected cases and negative cases; shared executor changes run the core suite; packaging changes verify both ZIPs' contents, hash readback, and execution after relocation.
- Screenshots/rendering use a real GPU. Desktop exports identify the Windows and template versions. Headless or audio-state checks cannot replace visual or listening acceptance.
- Positive cases combine logs, exit codes, assertions, and actual outputs. A passing negative case means only that the expected failure was detected. Do not remove assertions, ignore errors, or clear user caches to obtain a pass.

PRs state the actual commands executed, engine version, platform, results, and untested scope. Raw evidence may be attached to the PR/Release or provided through accessible links; do not refer only to ignored local `artifacts/`. Record historical reports separately from current validation, and never include unexecuted checks in the tested scope.

## Licensing, releases, and remaining governance work

Code and original examples use the [MIT License](LICENSE). Identify third-party resources' sources, licenses, and redistribution conditions; do not include unauthorized material.

Before release, synchronize the root manifest, Codex/Claude Code/Cursor compatibility manifests, Gemini extension manifest, marketplace entry, and necessary version notes. Keep README.md as the primary English version and README.zh.md as the Simplified Chinese version; cross-link both and synchronize installation methods and boundaries. Generate installation/source ZIPs, read back SHA256 hashes, and validate relocation before maintainers publish the version tag and attachments. Source archives include the contribution guide and templates. Both ZIPs include LICENSE, both READMEs, and all host manifests. Published tags and attachments remain unchanged; subsequent changes ship through new releases.

`AGENTS.md` contains the owner's local development rules. It is excluded by `.gitignore`, is not committed to the remote, and is not included in release packages. Public contribution procedures belong in this guide, Issue/PR formats in `.github/` templates, skill technical contracts and validation commands in `docs/authoring.md`, and license terms in `LICENSE`.

Structure CI, protected branches, and independent reviewers are not currently configured. Documented rules do not mean GitHub already enforces them. Separate Issues should configure CI with minimum permissions, required checks, and review protection, and add reproducible maintenance dependencies/schema. Real GPU and desktop tests still require suitable execution environments.
