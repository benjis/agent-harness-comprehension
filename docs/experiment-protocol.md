# Experiment protocol v2: execution-time information gain

## Status

Protocol version: 2, draft for the current research phase. This document defines an executable artifact-discrimination study followed by a single-reviewer formative self-study. A later multi-reviewer efficacy design is preserved separately below and is not the current procedure.

The Pi extension is the primary treatment generator. DeepSeek Harness is not a study dependency. The ParcelFlow Ruby tasks, hidden tests, templates, and a rewritten harness-neutral study runner now live under `evaluation/` in this repository.

Only one reviewer is currently available. The self-study can validate the protocol and produce case evidence, but it cannot estimate a causal treatment effect: reviewer, task, order, learning, and condition cannot all be separated with one observation per condition.

## Decision this protocol must support

The next phase must decide whether execution-time semantic checkpoints provide reliable, decision-relevant information that cannot be recovered equivalently from the frozen final repository, diff, task, and test results.

The protocol is not intended to prove that any summary helps. It separates three questions:

1. Does an additional review guide help compared with ordinary review materials?
2. Does execution-time evidence help beyond a time- and length-matched post-hoc guide?
3. Is any additional benefit large enough to justify capture cost, divergence risk, and harness complexity?

The second question is the primary research question. If runtime-enhanced and post-hoc guides perform equivalently, the execution-time hypothesis is not supported even if both outperform ordinary review.

The current one-reviewer phase cannot answer those comparative questions causally. It tests their prerequisites: whether a reliable runtime information increment exists, whether the packets make that increment usable, and whether a later efficacy study is justified.

## Hypotheses

### Primary hypothesis

For a completed non-trivial agent-generated change, a review guide that combines final-state evidence with bounded execution-time semantic checkpoints will reduce median time-to-understanding relative to a matched post-hoc guide, without materially reducing correctness or confidence calibration.

### Mechanism hypothesis

Execution-time capture will preserve at least one auditable causal fact on each medium or non-trivial task that:

- affected the implementation path;
- matters to review, impact prediction, maintenance, or defect localization; and
- cannot be recovered with equivalent confidence from the final task, repository, diff, and tests alone.

Examples include a failed path that explains a non-obvious boundary, a revised hypothesis, or a rejected alternative whose constraint remains relevant.

### Null and narrowing outcomes

The execution-time hypothesis is weakened or rejected if:

- runtime-enhanced guides are equivalent to matched post-hoc guides;
- checkpoints are frequently absent, generic, stale, contradicted, or unverifiable;
- runtime information improves only narrative detail and not a scored comprehension outcome;
- additional information increases review time or overconfidence;
- capture and maintenance cost is disproportionate to any observed benefit.

If value appears only on tasks with genuine revisions or failed paths, narrow the mechanism to sparse transition capture rather than general comprehension telemetry.

## Scope

This protocol covers:

- one pinned Pi version and one pinned comprehension-extension revision;
- one implementation model and fixed model settings during the pilot;
- completed local Git changes produced with the Pi extension active;
- three initial ParcelFlow Ruby tasks;
- researcher-only artifact audit before human exposure;
- a three-condition, single-reviewer formative self-study if the audit passes.

This protocol does not cover:

- comparison between models or harnesses;
- a production-ready ledger format;
- long-term project memory;
- repository-wide onboarding documentation;
- raw chain-of-thought capture;
- a UI, graph database, vector database, or remote service;
- a confirmatory or generalizable effectiveness claim.

## Why the first dogfood run is insufficient

The existing Pi dogfood established feasibility but did not exercise the intended mechanism strongly enough:

- one session produced 36 execution events and no semantic events, so its mental model was empty;
- the later session produced 82 events but only 8 semantic events;
- that session inspected and validated the extension without implementing a real change;
- no current constraint or invariant was recorded;
- some historical failures were supplied after the original events rather than captured when the transition occurred.

These are useful instrument findings. They are not evidence that runtime capture improves comprehension. The next runs must contain real implementation work and must be evaluated against a strong post-hoc comparator.

## Study stages

The protocol has two gates. Do not begin the review sessions until Stage 1 passes.

```text
Stage 0: freeze the instrument and study inputs
                     |
                     v
Stage 1: researcher-only artifact discrimination
                     |
          pass ------+------ fail
           |                    |
           v                    v
Stage 2: one-reviewer      redesign, narrow,
formative self-study       pivot, or stop
```

## Stage 0: freeze the instrument and study inputs

### Pin the run configuration

Before the first eligible run, record:

- Pi repository revision and Pi version;
- comprehension-extension revision and schema version;
- implementation model, provider, reasoning setting, and sampling settings where exposed;
- complete implementation instruction version;
- operating system, Node version, Ruby version, and Git version;
- visible-test command and timeout;
- post-hoc/runtime guide generator version, prompt version, and word budget;
- reproducible assignment seed.

Do not change these between study tasks without recording a protocol amendment. A blocking reliability fix starts a new instrument version; earlier runs remain reported as feasibility evidence and are not silently pooled with the new version.

### Migrated Ruby research assets

The following assets have been migrated into the harness-neutral `evaluation/` area in this repository:

- `fixtures/parcel_flow/`;
- `tasks/*.json`;
- `hidden_tests/*.rb`;
- answer and score templates;
- project preparation, hidden verification, review-session, condition-assignment, and analysis behavior that is independent of DSH.

The DSH trial runner, profile installation, settlement codes, two-condition assumptions, and comprehension-package format were not migrated as normative behavior. `evaluation/PROVENANCE.md` records the origin and license. The evaluation now runs without access to the earlier repository.

The evaluation workflow separates:

1. preparing a clean task workspace;
2. importing a completed Pi run and ledger;
3. freezing the final repository and diff;
4. running visible and hidden tests on frozen copies;
5. generating and registering matched post-hoc and runtime-enhanced guides;
6. auditing claims;
7. building condition-masked review packets;
8. recording review sessions;
9. scoring and analysis.

### Initial task set

Use the three existing ParcelFlow tasks:

| Task | Role in this study | Expected runtime advantage |
|---|---|---|
| `small-validation` | Negative-control-like small task | Little or none; a useful treatment should not invent complexity |
| `medium-atomic-reservation` | Multi-step invariant and failure-order task | Possible value from implementation choice and validation ordering |
| `nontrivial-idempotent-dispatch` | Cross-component state and side-effect task | Strongest opportunity for a causal decision or rejected alternative |

Before implementation, extend each private rubric with:

- one task-specific impact-prediction question;
- the expected control/data flow;
- accepted alternative implementations;
- critical and non-critical defect probes;
- claims that are inferable from final state versus claims that would require trajectory evidence.

Do not expose private rubrics or hidden tests to the implementation agent or reviewers.

## Conditions

Every condition for a task uses the exact same completed implementation. Packet generation occurs only after the repository is frozen.

### Condition O: ordinary review

Provide:

- task statement;
- frozen final repository;
- Git diff from the admitted baseline;
- visible-test command and output.

Do not provide the agent transcript, semantic ledger, hidden-test output, private rubric, or a generated review guide.

### Condition P: matched post-hoc guide

Provide Condition O plus `review-guide.md` generated after implementation from only:

- task statement;
- frozen repository;
- diff;
- visible-test command and output.

The post-hoc generator must not receive the Pi session, runtime event ledger, implementation summary, hidden tests, hidden-test output, or private rubric.

### Condition R: runtime-enhanced guide

Provide Condition O plus a file with the same name and structure, `review-guide.md`. Generate it from the same final-state inputs as Condition P plus the bounded semantic checkpoint ledger.

Do not expose the raw ledger as additional reviewer material in this formative study. Raw execution events and the session remain researcher-only. This keeps the conceptual comparison focused on information quality rather than on the ability to search a larger packet.

The Pi extension's existing deterministic `mental-model.md` remains a preserved instrument output and an input to reliability analysis. It is not used directly as the Condition R guide because it does not independently verify current-state claims against the frozen final repository.

### Matching P and R

Conditions P and R must use:

- the same generator model and settings;
- the same prompt structure except for the runtime-evidence input;
- the same schema and section order;
- the same citation rules;
- a maximum of 750 prose words, excluding headings and compact evidence references;
- total prose length within 10% for a given task;
- the same packet filename and review instructions.

If word-budget matching would require filler, shorten the longer guide instead. Do not pad the shorter guide with low-value content.

Generate and audit one structured current-state evidence model from the frozen final inputs, then reuse it unchanged in P and R. Only the decision/history material may differ:

- P receives decision context that can be supported from final-state evidence alone;
- R receives the same final-state context plus eligible semantic checkpoints;
- R may replace a weaker post-hoc inference with a supported runtime transition, but the replacement must be visible in the claim audit;
- neither condition may regenerate or rewrite the shared current-state model independently.

This prevents ordinary generation variance in architecture, flow, impact, or validation prose from being mistaken for an execution-time effect.

Both guides should contain these sections when supported:

1. change and responsibilities;
2. control and data flow;
3. constraints and invariants;
4. impact and likely modification points;
5. validation and unresolved risks;
6. decisions, revisions, and rejected paths.

Current-state claims must cite final-state evidence. Runtime events may contribute to the final section and may explain a current decision, but they may not override contradictory source or test evidence. Label claims that are runtime-reported but not independently verifiable.

Generate each guide once under a versioned retry policy. Retry only for a declared transport, schema, or length failure; retain the failed attempt metadata. Do not manually edit, select among several valid candidates, or regenerate a guide after seeing audit or reviewer outcomes.

## Trial production

### Prepare the workspace

For each task:

1. create a new ParcelFlow workspace from the fixture;
2. initialize a clean Git baseline commit;
3. place only the public task in the workspace;
4. verify the visible tests pass at baseline where expected;
5. verify the Pi extension writes outside tracked source paths or into an explicitly excluded local artifact directory;
6. record the baseline revision and tree fingerprint.

### Run the implementation

Start the pinned Pi build with the comprehension extension active. Give the agent only the task and normal repository instructions. Do not prompt it to manufacture failed paths, use every event type, or optimize for the study rubric.

The operator may intervene only for an actual environment failure or imminent scope violation. Record every intervention verbatim in the run manifest.

Preserve researcher-only materials:

- Pi session record or observable transcript;
- complete comprehension ledger;
- rendered v0 mental model;
- extension status and persistence errors;
- model/tool usage where available;
- start, settlement, and completion timestamps;
- operator interventions and protocol deviations.

These materials are for instrument audit. They are not included in review packets.

### Freeze the change

After Pi settles:

1. stop all task-owned mutation;
2. record final Git status, diff, revision, and a deterministic worktree fingerprint;
3. copy the repository into an immutable run directory, excluding Git metadata and comprehension artifacts;
4. run visible tests on a copy of the frozen repository;
5. run hidden tests on a separate copy;
6. preserve hidden results for researchers only;
7. generate P and R from the same frozen evidence cut.

The final repository is authoritative. A semantic event contradicted by the frozen repository is an artifact defect, not an alternative truth.

### Eligibility and failures

A completed change can produce review packets only when:

- the implementation process completed normally;
- the frozen repository and diff are complete;
- visible tests pass;
- both P and R guides can be generated and audited;
- packets contain no prohibited or sensitive data.

Hidden-test failure does not make a run ineligible. It creates an opportunity to measure defect detection.

Implementation failure, missing checkpoints, guide-generation failure, ledger corruption, and privacy rejection must be reported as treatment or study costs. Do not silently discard them. During the frozen formative study, do not rerun a task merely to obtain a more interesting trajectory. A replacement run requires a documented protocol amendment and a new run identifier.

## Stage 1: artifact discrimination audit

### Purpose

Before asking whether humans benefit, establish whether Condition R contains a trustworthy information increment over Condition P.

### Unit of audit

Split each P and R guide into atomic factual or causal claims. One claim should be independently classifiable without relying on another sentence.

For each claim record:

| Field | Values |
|---|---|
| Final-state support | `supported`, `contradicted`, `stale`, `not-verifiable` |
| Runtime support | `observed-transition`, `agent-reported`, `not-present` |
| Recoverability | `post-hoc-recoverable`, `runtime-unique`, `uncertain` |
| Decision relevance | `none`, `contextual`, `review-relevant`, `critical` |
| Target outcome | architecture, workflow, invariant, impact, defect, review decision |
| Severity if wrong | `low`, `medium`, `high` |

`runtime-unique` means that the frozen final materials do not support the claim with equivalent confidence. It does not mean merely that Condition P happened to omit an inferable fact.

Use the observable Pi session and event ordering to audit whether an alleged transition occurred. Do not infer or request hidden chain-of-thought.

### Additional instrument measures

Record for each run:

- execution-event and semantic-event counts;
- semantic types and supersession links;
- time of first semantic event and final closure event;
- missing expected checkpoint classes;
- duplicate and generic event rate;
- current-state contradiction and staleness rate;
- capture failures and renderer failures;
- added tool calls, turns, tokens, wall time, and storage;
- prohibited-data findings;
- P and R generation tokens, time, and retries.

### Stage 1 gate

Proceed to human review only when all of the following are true:

1. The medium and non-trivial tasks each contain at least one runtime-unique, review-relevant claim confirmed by the observable session history.
2. Neither P nor R contains a high-severity contradicted current-state claim.
3. Fewer than 5% of current-state claims in either guide are contradicted or stale.
4. The medium and non-trivial runs contain a usable goal, final decision/current-state closure, invariant or constraint, and validation record, whether captured directly or produced by an explicitly versioned closure step.
5. P and R meet the matching and word-budget rules.
6. No prohibited data appears in reviewer artifacts.
7. All capture and generation failures are accounted for in the feasibility report.

The small task is allowed to contain no runtime-unique claim. That is evidence of appropriate sparsity, not automatically a failure.

If Gate 1 fails because checkpoints are absent or malformed, make one bounded capture redesign and repeat Stage 1 under a new instrument version. If it fails because no reliable information increment exists, do not run the formative review sessions; pivot to post-hoc evidence generation or stop the execution-time claim.

## Stage 2: single-reviewer formative self-study

### Reviewer and interpretation limit

The project author is the only current reviewer. Record:

- professional experience;
- Ruby familiarity;
- code-review frequency;
- prior familiarity with ParcelFlow or the exact tasks;
- recent experience reviewing agent-generated code.

Prior familiarity with the fixture, task rubric, or completed change is a protocol limitation rather than a removable reviewer exclusion when the author fills both researcher and reviewer roles. Record what was known before each session and do not inspect the private rubric, hidden tests, condition key, or completed change after the implementation run until the associated review answer is frozen.

The three sessions produce one observation per condition. They are useful for finding broken instructions, timing problems, misleading claims, poor reading order, and clear individual cases. They are not a sample-size estimate and cannot support a treatment-effect, go/no-go, or general effectiveness claim.

### Assignment

Use a reproducible seeded assignment:

- the reviewer sees each task once;
- the reviewer sees O, P, and R once;
- each task receives exactly one condition;
- packet order is shuffled independently from condition assignment;
- packet identifiers do not disclose condition;
- the researcher key containing condition and hidden-test outcomes remains private.

The reviewer cannot be fully blinded because the presence of a guide is visible and the author helped design the artifacts. Use identical guide filenames and keep the condition key closed until all three answers and initial scores are frozen. Report any recognition of a condition or remembered rubric fact as a deviation.

### Review procedure

For each packet:

1. start the timer when the packet becomes accessible;
2. require all file access through the study reader so opens and timestamps are recorded;
3. allow a maximum of 20 minutes;
4. ask the reviewer to commit answers once, without reopening materials for the primary score;
5. retain partial answers at timeout;
6. collect confidence for each scored answer, not only one global confidence value;
7. collect cognitive load on a 1–7 scale after the task.

Ask the reviewer:

1. What changed, and which components own the new behavior?
2. What is the main control/data flow?
3. Which invariant must remain true?
4. For the task-specific requirement change in the private protocol, where would you modify the system and what else could be affected?
5. Is there a defect or unresolved risk? Where would you inspect first?
6. Would you approve, reject, or request changes, and what evidence supports that decision?

### Scoring

Freeze answers before scoring. The author performs an initial score using the private task rubric, frozen repository, diff, visible and hidden test outcomes, and researcher evidence index before opening the condition key. This masks the condition during initial scoring but does not make the score independent.

Score each field from 0 to 2:

- component and responsibility model;
- control/data-flow identification;
- invariant recognition;
- impact prediction;
- defect localization;
- review decision quality;
- evidence traceability.

Use anchored task-specific examples for `0`, `1`, and `2`. Inter-rater agreement cannot be measured with the current reviewer pool. If an independent scorer becomes available later, preserve the frozen answers and original scores so a blinded second score can be added without replacing them.

Also classify guide defects:

- `missing-evidence`;
- `unsupported-rationale`;
- `contradicted-current-state`;
- `stale-history`;
- `semantic-compression`;
- `reading-order`;
- `excessive-detail`;
- `runtime-noise`;
- `false-confidence-risk`.

## Outcomes and analysis

### Descriptive comparison

Describe R, P, and O separately. R versus P remains the conceptual comparison, but the single-reviewer data cannot isolate runtime evidence from task difficulty, order, or learning.

Recorded primary measures:

- time-to-committed answers;
- aggregate primary correctness across component model, flow, invariant, impact, defect localization, and review decision;
- confidence calibration error.

Report the raw observation for each task and condition. Do not calculate an effect size, uncertainty interval, statistical test, or release decision from one observation per condition.

### Secondary descriptions

- P and O observations, without attributing differences to the guide;
- R and O observations, without attributing differences to runtime evidence;
- whether the R session used the runtime-unique claims identified in Stage 1;
- task complexity, order, and prior-familiarity context for every observation.

Secondary outcomes:

- unique files opened and revisits;
- time to first relevant source file;
- evidence traceability;
- defect detection;
- approval/rejection accuracy;
- cognitive load;
- overconfidence rate;
- artifact defects noticed by reviewers;
- total implementation, capture, generation, and maintenance cost.

### Formative completion criteria

The self-study is complete when:

- all three packets can be reviewed through the recorded workflow;
- answers, per-answer confidence, opened files, timing, and cognitive load are captured;
- scoring can be completed without exposing the condition key first;
- artifact defects and protocol deviations are recorded;
- Stage 1's runtime-unique claims can be checked against the reviewer's actual use or non-use of them;
- the report prominently marks every result as formative and causally uninterpretable.

Observed time or score differences may motivate a later task or artifact redesign, but they must not trigger production hardening or a claim that R outperforms P. A later efficacy study requires additional independent reviewers or a substantially larger set of calibrated, non-repeated task variants.

## Decision outcomes

### Continue

Continue limited mechanism development only if Stage 1 finds reliable runtime-unique information and the self-study shows that the information can be used without creating a serious artifact or workflow failure. This is permission for another research iteration, not evidence of human benefit.

Next work may then include:

- a bounded, versioned semantic schema;
- stronger final-state reconciliation;
- a second harness adapter;
- ablations for semantic events, execution metadata, closure, and supersession;
- a powered confirmatory study.

### Narrow

If value appears only in failed paths, revisions, or rejected alternatives, narrow capture to those transitions. Treat final-state architecture, impact, invariants, and validation as post-hoc evidence-grounded responsibilities.

### Pivot

If Stage 1 finds no reliable runtime information increment, but the post-hoc guide remains coherent and useful during rehearsal, stop treating execution-time capture as the main mechanism. Continue with a simpler revision-pinned post-hoc reviewer package.

### Stop

Stop or materially reformulate the hypothesis if runtime capture is frequently absent, contradicted, misleading, privacy-unsafe, or too unreliable to generate consistently. Treat a serious false-confidence or workflow failure in the self-study as a reason to redesign before any further review experiment.

## Future efficacy study, not currently active

Run this stage only if the artifact audit establishes a reliable runtime information increment and the formative self-study finds no blocking workflow or false-confidence failure.

Use a within-participant randomized crossover where each participant reviews different calibrated tasks under O, P, and R. Every frozen implementation must be reviewed under every condition by different participants; never compare different agent implementations as if they were conditions. Recruit enough independent reviewers to provide at least six observations per condition for a directional pilot, then use observed variance to set a sample-size target for any confirmatory study.

Record participant experience and exact-task familiarity. Balance task and condition order with a reproducible seed. Keep condition labels, hidden tests, private rubrics, and researcher-only sessions unavailable until answers and initial scores are frozen. Double-score at least 20% of observations and report inter-rater agreement.

Primary outcomes remain:

- time-to-committed answers;
- architecture and control/data-flow comprehension;
- invariant recognition and impact prediction;
- defect localization and review-decision quality;
- confidence calibration.

Report medians, distributions, within-participant differences, per-task results, effect sizes, and uncertainty intervals. Treat missing artifacts and capture failures as treatment costs. Stratify by task complexity, repository, reviewer experience, and failure mode.

Before recruiting, pre-register the practical effect threshold and non-inferiority margin. The prior planning value was a 15% median time reduction for R versus P with no more than a 5 percentage-point correctness decrease, no material decline in defect or review decisions, and no increase in overconfidence. Reconfirm those values using the formative task timings rather than treating them as immutable.

Threats requiring explicit mitigation include:

- participants learning the study vocabulary;
- unequal guide length or reading time;
- checkpoint behavior varying by model or task;
- rubrics rewarding concepts emphasized by the treatment schema;
- repeated exposure improving general review skill;
- synthetic defects failing to represent maintenance work;
- shifted effort from reviewers to capture and artifact generation.

This later study may support a directional continue/stop decision. It still cannot establish generality across harnesses, models, languages, repositories, or professional settings without broader follow-up evidence.

## Data handling

Reviewer packets must not include:

- prompts other than the public task;
- assistant messages or raw session transcripts;
- hidden tests or hidden-test output;
- credentials or environment secrets;
- raw tool output unrelated to the frozen review evidence;
- private chain-of-thought;
- private task rubrics or condition labels.

Researcher-only Pi sessions may contain normal observable messages and tool records needed to audit event timing. Keep them local, access-controlled, and separate from publishable/anonymized results. Record retention and deletion dates before beginning review sessions.

## Protocol deviations

Record every deviation with:

- run or reviewer identifier;
- timestamp;
- stage and affected condition;
- reason;
- whether the deviation was known before outcomes were inspected;
- remediation;
- inclusion/exclusion decision.

Do not change task rubrics, artifact prompts, scoring anchors, thresholds, or exclusions after inspecting condition outcomes without publishing the amendment and reporting results under both the original and amended interpretation where possible.

## Required deliverables

Stage 0:

- migrated ParcelFlow research assets and harness-neutral Ruby study runner;
- pinned run manifest schema;
- versioned P/R guide schema and generator prompts;
- task-specific impact questions and scoring anchors;
- harness-neutral evaluation commands and tests.

Stage 1:

- three frozen Pi implementation runs;
- O, P, and R packets for each run;
- claim-level artifact audit;
- capture/generation cost report;
- Gate 1 decision and any protocol amendment.

Stage 2, only after Gate 1:

- reproducible single-reviewer condition assignment;
- three completed review sessions and condition-masked initial scores;
- observation dataset;
- analysis script, results, and report;
- deviations and missing-data report;
- a formative recommendation to continue investigating, narrow, pivot, or stop, without an efficacy claim.

## Immediate implementation order

The migrated runner, frozen-run importer, versioned artifact contracts, deterministic matched-guide renderer, exhaustive claim-audit registration, generation-cost capture, and Gate 1 evaluator are implemented.

1. Rehearse `small-validation` end to end with Artifact Pipeline v1.
2. Run the medium and non-trivial Stage 1 trials.
3. Generate each artifact set once, audit every claim, and retain failures and costs.
4. Evaluate Gate 1 before reviewing the masked packets or hardening the Pi extension further.
5. Complete the three single-reviewer sessions only after a passing gate and publish a formative, non-causal report.
