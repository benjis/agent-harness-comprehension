# Experiment plan

> The operational next step is the single-reviewer formative study in [experiment-protocol-v2.md](experiment-protocol-v2.md). It validates the mechanism and study workflow but cannot estimate a treatment effect. The multi-reviewer design below remains the later efficacy-study design.

## Objective

Test whether structured execution-time comprehension evidence helps developers understand completed agent-generated changes faster and at least as correctly as ordinary review materials and a time-matched post-hoc summary.

The prototype is the treatment generator. Its existence and automated tests are not evidence of human benefit.

## Conditions

Use a within-participant, randomized crossover design where practical. Each participant reviews different but calibrated tasks under each condition, and each completed implementation is reviewed in all conditions by different participants.

### Baseline A: ordinary review

Provide the task, final repository, diff, and test results.

### Baseline B: post-hoc summary

Provide Baseline A plus a summary produced after implementation from the same final artifacts. Match the treatment's reading-time or word budget.

### Treatment: comprehension ledger

Provide Baseline A plus `mental-model.md` and access to the structured ledger. Do not provide raw agent transcripts to any condition.

Using both baselines separates “any summary helps” from the stronger claim that execution-time structured evidence adds value.

## Task sampling

Sample multiple repositories, languages, models, and task sizes. Include feature work, refactoring, and defect repair. Each task should contain at least one meaningful architectural relation, impact question, or latent defect that cannot be answered from a file-name inventory alone.

Freeze one completed implementation per task before building review packets. All conditions must inspect the same code and test outcomes. Do not compare different agent implementations across conditions.

Pre-register exclusions such as failed implementation, corrupted packet, prior participant familiarity with the exact change, or incomplete review session.

## Procedure

1. Record participant experience and familiarity with the language/domain.
2. Randomize task order and condition assignment with a reproducible seed.
3. Start a timer when the packet becomes available.
4. Ask the participant to stop when ready to answer, subject to a fixed maximum.
5. Collect answers without reopening materials for the primary comprehension score.
6. Collect confidence per answer, not only once for the whole task.
7. Record files and artifacts opened, time spent, and optional cognitive-load rating.
8. Score answers blind to condition using a task-specific rubric and two reviewers for a subset.

## Outcomes

### Primary outcomes

- **Time-to-understanding:** seconds until the participant commits to final answers.
- **Architecture comprehension:** scored explanation of responsibilities, state ownership, boundaries, and main control/data flow.
- **Impact prediction:** correctness and completeness when predicting effects of a plausible requirement change.
- **Bug localization:** ability to identify the likely component or code region for a seeded or naturally occurring defect.
- **Review decision quality:** correctness and evidence quality when approving, rejecting, or requesting changes, including whether the participant can justify the decision without repeating the agent's recommendation.

### Secondary outcomes

- **Invariant recognition:** identification of behaviors that must remain true.
- **Confidence versus correctness:** calibration error, overconfidence rate, and correlation between confidence and rubric score, especially for approve/reject decisions.
- **Divergence rate:** proportion of artifact claims contradicted, unsupported, stale, or materially incomplete relative to final code.
- **Navigation cost:** unique files opened, revisits, and time before first relevant file.
- **Cognitive load:** participant-reported effort on a fixed scale.
- **Maintenance cost:** capture latency, model tokens/cost, storage, failures, schema changes, and maintainer time per task.

## Scoring

Create a private task rubric before participant review. Score architecture, impact, bug localization, and invariants on a small anchored scale, for example:

- `0`: absent or wrong;
- `1`: partially correct, missing an important relation;
- `2`: correct and sufficiently complete for the task.

For each factual artifact claim, label `supported`, `contradicted`, `stale`, or `not verifiable`. Measure inter-rater agreement on at least 20% of packets and resolve large disagreements without seeing condition labels.

## Analysis

- Compare within-participant outcome differences where the crossover design allows it.
- Report medians and distributions, not only means.
- Include effect sizes and uncertainty intervals.
- Stratify by task size, participant experience, repository, model, and failure mode.
- Treat missing artifacts and capture failures as treatment costs, not silent exclusions.
- Publish the analysis script, anonymized measurements, protocol deviations, and negative results where consent and repository licenses allow.

The initial dogfood run is for instrument validation only. Before a confirmatory study, use pilot variance to set a sample-size target and pre-register the primary comparison and practical-effect threshold.

## Success and failure thresholds

A promising result requires a practically meaningful reduction in median time-to-understanding with no material decrease in any primary correctness outcome, no increase in overconfidence, and an acceptable maintenance cost.

The hypothesis is weakened or falsified if the treatment is slower, less correct, less calibrated, frequently divergent, or equivalent to a time-matched post-hoc summary. Benefits that appear only for one repository or participant group should narrow the claim rather than be generalized.

## Threats to validity

- Participants may learn the study's preferred vocabulary.
- Treatment artifacts may be longer and receive more reading time.
- Agent checkpoint behavior may vary by model or prompting.
- Task rubrics may reward information emphasized by the treatment schema.
- Repeated exposure may teach participants how to inspect agent changes generally.
- Synthetic defects may not represent maintenance work.
- The tool may shift effort from reviewers to agents rather than reduce total cost.

Mitigate these with time/length matching, counterbalancing, frozen implementations, blinded scoring, diverse tasks, and explicit total-cost reporting.

## Minimal pilot

Start with three calibrated tasks and at least four reviewers so every reviewer sees each condition once. Use the pilot to verify packet generation, timing, scoring clarity, divergence review, and capture-cost instrumentation. Do not use this small pilot as proof of general effectiveness.
