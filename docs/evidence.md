# Validation and research evidence

**English** | [简体中文](evidence.zh.md) · [Documentation](README.md)

## Capability contract

[capabilities.json](capabilities.json) maps the 23 Skills to official sources, examples, test IDs, prerequisites and tested/untested scope. Its recorded baseline is Godot 4.7.2 on Windows. Read individual records and their linked evidence before claiming support for a particular task or platform.

## Recorded validation batches

These are dated records from prior work, not new test runs performed by the documentation reorganization.

| Batch | Human-readable context | Machine-readable result |
|---|---|---|
| 2026-10-11 original baseline | [Validation report](validation.md) (Chinese; 18 Skills at that time) | [validation-results.json](validation-results.json) |
| 2026-10-12 host packaging; subsequent updates appended | [Compatibility history](compatibility.md) (English) | Results/limitations recorded in the report and linked PRs |
| 2026-10-13 0.2.0 deepening to 23 Skills | [Research and implementation index](research/README.md), [coverage](coverage.zh.md) (Chinese) | [deepening-validation.json](deepening-validation.json) |
| 2026-10-13 0.2.1 native diagnosis, localization and Web | [Validation report introduction](validation.md), [compatibility update](compatibility.md) | [native-workflows-validation.json](native-workflows-validation.json) |
| 2026-10-13 0.2.2 priority tasks and protected saves | [Priority task report](priority-skills-validation.md) (English) | [priority-skills-validation.json](priority-skills-validation.json) |

The 0.2.2 report records 53 expected outcomes: 42 normal passes, six intended failures, one intended timeout, two unsupported controls and two missing-toolchain controls. The eleven controls demonstrate recognition/preflight, not successful execution of those operations. That batch is the latest versioned report in this index; its results do not extend to every installed host or platform.

## Research trail

- [Baseline and technical choices](research.md) records source pinning and initial native boundaries.
- [Research index](research/README.md) links domain research, implementation, self-review and task evaluation.
- [Page inventory](research/4.7-page-inventory.json), [generated-page reviews](research/generated-page-reviews.json) and [baseline snapshot](research/baseline-20261013.json) are research records, not runtime test results.

Raw local logs/downloads live in ignored `artifacts/` and are not shipped. Reproduction of inventory/hash checks requires the original source/HTML snapshots. Report links or attachments in the relevant PR provide reviewable evidence; the mere existence of an ignored local path does not make its content accessible to other readers.

## Boundaries that still matter

Recorded native behavior is Windows-specific. Real rendering and audio listening are separate from headless/state checks. Manifest/package validation does not certify installed-host implicit Skill selection. Browser, public networking, mobile and other platform variants require their own evidence. See the individual batch reports for exact conditions, exceptions and commands, and [testing](testing.md) for selecting a new verification run.
