# Pi comprehension formative study

This directory contains the self-contained Ruby evaluation assets for [`docs/experiment-protocol.md`](../docs/experiment-protocol.md). It uses only Ruby's standard library, Git, and artifacts imported from a completed Pi run. DeepSeek Harness is not required.

## Study boundary

The current setup has one reviewer. It is a formative self-study: it can validate packet generation, timing, scoring, artifact defects, and individual cases, but it cannot estimate a causal treatment effect. Each of the three tasks is reviewed once under one of the three conditions:

- `ordinary` — task, frozen repository, diff, and visible tests;
- `post_hoc` — ordinary materials plus a final-evidence-only guide;
- `runtime` — ordinary materials plus a matched runtime-enhanced guide.

The condition assignment remains hidden inside `researcher-key.json` until the review sessions are complete.

## Verify the harness

```sh
npm run test:evaluation
```

Ruby 3.3 is used in development. No gems are required.

## Prepare a task

```sh
evaluation/bin/study prepare small-validation /absolute/path/to/workspace
```

Run the pinned local Pi build with the comprehension extension inside that workspace. After Pi has settled, import the frozen result. Pass `-` instead of a ledger path to record a capture failure.

```sh
evaluation/bin/study import-run \
  small-validation \
  /absolute/path/to/workspace \
  /absolute/path/to/workspace/.pi/comprehension/SESSION/events.jsonl \
  /absolute/path/to/runs/small
```

The importer copies the final repository, includes tracked and untracked changes in `diff.patch`, runs visible and hidden tests on copies, and keeps the ledger under the researcher-only `research/` directory.

## Register structured artifacts

Use the versioned prompts in `prompts/` to produce one current-state document, separate P/R history documents, and generation metadata. The example contracts are in `schemas/`. Register them once:

```sh
evaluation/bin/study register-artifacts \
  /absolute/path/to/runs/small \
  /absolute/path/to/current-state.json \
  /absolute/path/to/post-hoc-history.json \
  /absolute/path/to/runtime-history.json \
  /absolute/path/to/generation-metadata.json
```

The command validates evidence paths and runtime event IDs, records canonical artifact, evidence, ledger, and prompt hashes, and deterministically renders both guides from the same current-state model. It enforces the 750-word cap and 10% length tolerance. Generated prose cannot be manually attached or regenerated after registration.

## Audit claims and evaluate Gate 1

Audit every generated claim with the versioned audit prompt, then register the complete audit:

```sh
evaluation/bin/study audit-run \
  /absolute/path/to/runs/small \
  /absolute/path/to/small-claim-audit.json
```

After all three audits are complete, evaluate the pre-registered gate:

```sh
evaluation/bin/study gate \
  /absolute/path/to/gate-1.json \
  /absolute/path/to/runs/small \
  /absolute/path/to/runs/medium \
  /absolute/path/to/runs/nontrivial
```

The gate requires one small, medium, and non-trivial run. It rechecks artifact, evidence, ledger, prompt, and rendered-guide integrity, then checks runtime-unique relevance, current-state accuracy, semantic closure, matching, privacy, and failure accounting. Only a passing report changes the three runs to `eligible`; packet construction refuses every earlier state.

## Run the Instrument v2 diagnostic

The pre-registered v2 diagnostic is separate from Gate 1. Use `prompts/trajectory-positive-control-v1.md` for the single artificial implementation run, then use `prompts/closure-v2.md` once in the same settled Pi session without modifying source. Generate and audit the normal structured artifacts, then register the observed event IDs with the example contract in `schemas/diagnostic-registration-v1.example.json`:

```sh
evaluation/bin/study diagnostic-gate \
  /absolute/path/to/runs/nontrivial-v2 \
  /absolute/path/to/diagnostic-registration.json \
  /absolute/path/to/instrument-v2-diagnostic.json
```

The report evaluates Gate A closure reliability and Gate B trajectory capture separately. It requires the runtime claim to cite the ordered hypothesis, failure, and superseding revision. A pass records `reviewer_eligible: false` and leaves the run at `audit-complete`; this artificial positive control cannot open a reviewer packet or be pooled with the v1 runs.

## Run the fail-fast natural-task v2 gate

Use `prompts/natural-implementation-v1.md` without trajectory guidance, followed by `prompts/closure-v2.md` in the same settled session. After artifact registration and exhaustive claim audit, copy `schemas/natural-gate-registration-v1.example.json` and register the closure boundary plus any audited natural causal sequence:

```sh
evaluation/bin/study natural-gate \
  /absolute/path/to/runs/natural-medium \
  /absolute/path/to/natural-gate-registration.json \
  /absolute/path/to/natural-medium-gate.json
```

Phase 1 emits `continue` only for a valid medium run with a pre-closure runtime increment; a valid uniqueness failure emits `pivot-post-hoc`, and operational invalidity emits `inconclusive`. Phase 2 additionally requires the passing phase-1 report. Even two passes only emit `reviewer-study-ready`: both runs remain `audit-complete` and `reviewer_eligible: false` until the user explicitly starts the reviewer workflow.

## Build the one-reviewer assignment

After all three runs are eligible:

```sh
evaluation/bin/study formative \
  /absolute/path/to/study \
  ben \
  /absolute/path/to/runs/small \
  /absolute/path/to/runs/medium \
  /absolute/path/to/runs/nontrivial
```

Use `review-start`, `review-open`, and `review-finish` to record the sessions. Keep `researcher-key.json`, hidden-test results, rubrics, and run directories closed until all three answers are frozen.

After scoring, analyze with:

```sh
evaluation/bin/study analyze \
  /absolute/path/to/study/researcher-key.json \
  /absolute/path/to/completed-sessions \
  /absolute/path/to/scores \
  /absolute/path/to/analysis
```

The report is deliberately marked `formative-only`; it does not issue a continue or stop decision from one observation per condition.
