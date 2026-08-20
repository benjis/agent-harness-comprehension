# Pi comprehension formative study

This directory contains the self-contained Ruby evaluation assets for `docs/experiment-protocol-v2.md`. It uses only Ruby's standard library, Git, and artifacts imported from a completed Pi run. DeepSeek Harness is not required.

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

## Attach matched guides

Generate the guides according to the protocol, then register exactly one valid pair:

```sh
evaluation/bin/study attach-guides \
  /absolute/path/to/runs/small \
  /absolute/path/to/post-hoc-review-guide.md \
  /absolute/path/to/runtime-review-guide.md \
  /absolute/path/to/current-state.json
```

The command checks the shared headings, 750-word cap, and 10% length tolerance. It does not generate or manually repair guide content.

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
