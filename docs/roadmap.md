# Roadmap

This roadmap separates implemented prototype behavior from planned research and engineering. Dates are intentionally omitted until pilot results justify the next stage.

## Experimental lineage

- **Skill layer — Agentic Survivor:** post-hoc mental-model reconstruction exposed the difficulty of recovering failed paths and causal revisions.
- **DeepSeek Harness experiments:** explored comprehension as a harness-integrated concern with a different post-settlement design.
- **Current Pi prototype:** tests execution-time typed events, append-only history, explicit supersession, and deterministic rendering through native extension hooks.

The experiments share a problem statement, but their architectures should remain distinguishable so their mechanisms can be evaluated rather than blended.

## Current stage: prototype and dogfood

Implemented:

- Pi lifecycle and tool-event adapter.
- Typed semantic checkpoint tool.
- Append-only per-session JSONL ledger.
- Explicit supersession and current/history reconciliation.
- Deterministic Markdown mental-model renderer.
- `/comprehension` and `/comprehension-status`.
- Automated tests for the core storage, schema, reconciliation, and extension behavior.

In progress:

- Real-task dogfooding.
- Cataloging missing, noisy, contradictory, and sensitive events.
- Refining the baseline-versus-treatment protocol.

No controlled human-comprehension benefit has been established.

## Milestone 1: harden the research prototype

- Add bounded field-size and total-ledger limits at persistence time.
- Validate referenced supersession IDs and detect contradictory current records.
- Add schema versioning and migration fixtures.
- Add atomic renderer writes and explicit corruption diagnostics.
- Define retention and local artifact deletion guidance.
- Expand tests for cancellation, partial writes, concurrent calls, and malformed ledgers.
- Document exact Pi version compatibility.

Exit criterion: repeatable local sessions with known failure behavior and no silent capture of prohibited data in test fixtures.

## Milestone 2: instrument the pilot

- Build frozen review-packet generation for ordinary, post-hoc, and treatment conditions.
- Add timing, navigation, confidence, correctness, divergence, token, latency, and storage measurements.
- Create task-specific blinded scoring rubrics.
- Run protocol rehearsals and publish deviations.

Exit criterion: the study machinery produces complete, scoreable packets without condition-dependent implementation changes.

## Milestone 3: run and report the pilot

- Run diverse tasks with multiple reviewers.
- Score a subset twice and report agreement.
- Publish anonymized results, failure cases, and artifact examples where permitted.
- Decide whether to continue, narrow, redesign, or stop the hypothesis.

Exit criterion: a transparent directional result and a grounded decision about confirmatory evaluation.

## Milestone 4: test generality

Only if the pilot is promising:

- Add a second harness adapter behind a shared versioned event schema.
- Compare models and task types.
- Run ablations: execution metadata only, semantic events only, no supersession, post-hoc extraction, and deterministic versus model-written rendering.
- Evaluate maintainers on unfamiliar and familiar repositories.

Exit criterion: evidence about which mechanism helps, for whom, and under what conditions—not merely a larger feature set.

## Possible later work

- Evidence links verified against repository revisions.
- Integrity hashes and signed/exportable ledgers.
- IDE or web views over the same deterministic projection.
- Project-level reconciliation across sessions.
- Privacy policy enforcement and secret scanning.

These are not commitments. They depend on evaluation results and should not precede evidence that the core approach is useful.
