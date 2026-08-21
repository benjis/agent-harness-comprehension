# Research: comprehension debt in agent-generated software

## Abstract

Coding agents can shorten the time required to produce a working change. They do not automatically shorten the time required for a human to understand, verify, maintain, and safely extend that change. This project calls the accumulating gap **comprehension debt**.

The project tested whether a small comprehension layer inside an agent harness could preserve decision-relevant evidence during execution and later render a more useful mental model than a developer could obtain from final-state evidence alone. The artificial diagnostic established capture capability, repeated natural runs produced no reliable runtime information increment, and a controlled hybrid prerequisite produced auditable trajectory evidence. The intended human review did not complete because its chat-mediated file interface failed before a reliable decision was possible.

The hypothesis remains unproven and the research experiment is paused. The artifact may be redundant, noisy, costly, incomplete, or misleading. Those are first-class possible results. Current work has moved to iterative product development of Agentic Survivor's `comprehension-sync` workflow; that product response is informed by the formative observations here but is not efficacy evidence.

## Project lineage

The first approach to this problem was Agentic Survivor's Code Reading skill, which reconstructs a compressed mental model from observable artifacts after implementation. It demonstrated the value of organizing explanations around constraints, causal decisions, invariants, and executable paths rather than producing a file summary.

It also revealed a limit of the skill layer. By the time post-hoc reconstruction begins, failed attempts and revised hypotheses may have left little reliable evidence in the final code. The skill can infer a plausible rationale, but inference is not the same as preserving the causal transition when it happens.

That limitation motivated harness-level experiments: first with DeepSeek Harness, and then with Pi. The Pi prototype uses native lifecycle and extension hooks to capture typed checkpoints as a first-class session artifact. These implementations are experiments around one research question, not evidence that harness-level capture is superior.

The failed reviewer workflow exposed a second problem: a human can approve repeated next steps while summaries and serial file access fail to maintain a usable model of what the agent is building. Agentic Survivor's newer Comprehension Sync skill addresses that product problem during implementation through thin slices, decision pauses, direct source access, and mental-model handoffs. It is a separate product iteration, not a completed condition in this study.

## Problem: comprehension debt

Implementation throughput and human understanding are different variables. A change may compile, pass tests, and satisfy a task while its owner still cannot reliably answer:

- What responsibility changed, and why?
- Which constraints shaped the solution?
- Which alternatives failed or were rejected?
- What invariants must remain true?
- Where would a new requirement propagate?
- Where is a likely defect located?

When agent-generated changes accumulate faster than these questions can be answered, a project incurs comprehension debt. Like other forms of engineering debt, it may remain hidden until debugging, review, onboarding, or modification requires the missing model.

This definition does not assume agent-written code is worse than human-written code. It describes an ownership and information-transfer problem created by a throughput mismatch.

## Qualitative motivation: the missing understanding loop

In recent informal interviews, the project author spoke with engineering team leaders and developers from several companies about their use of agentic coding. A common theme was that implementation productivity had increased, while the limiting factor had shifted toward understanding what coding agents produced.

Participants described practical consequences around review and accountability. Agent-produced changes may be difficult or time-consuming for a human to review, yet the human is still expected to approve the work and take responsibility when it fails. A related risk appears when people make decisions from an agent's recommendation without possessing the mental model required to evaluate its assumptions, downstream effects, or failure modes.

This motivates a distinction between two kinds of participation:

- **Human in the decision loop:** a person supplies an approval, rejection, or choice.
- **Human in the understanding loop:** that person has enough causal and architectural understanding to make the judgment responsibly.

The first does not guarantee the second. A human checkpoint can become procedural rather than substantive if agent output grows faster than the reviewer can understand it.

These interviews are formative qualitative observations. The participants, interview protocol, sample size, and analysis have not been published as a formal study, so the observations should not be treated as prevalence estimates or evidence that the proposed comprehension layer is effective. They help define the problem and the outcomes that a controlled evaluation must test.

## Hypothesis

For non-trivial agent-generated changes, a harness-integrated comprehension layer that captures bounded, structured, decision-relevant evidence during execution will help developers form an accurate and actionable mental model faster than ordinary access to the task, final code, diff, tests, and a post-hoc summary.

The expected benefit is not a more polished narrative. It is improved ability to explain architecture, predict change impact, localize bugs, identify invariants, calibrate confidence, and justify review decisions independently of the agent's recommendation.

Current interpretation: the formative artifact gates do not support a claim that useful runtime trajectories occur reliably in the tested natural tasks. They do show that controlled trajectories can be captured. Runtime and post-hoc evidence are therefore treated as complementary: a revision-pinned post-hoc model is the default base, and audited runtime-unique history is an optional addendum. The active, narrower hypothesis is that this addendum may improve reviewer understanding when a verifiable trajectory exists; natural prevalence remains a separate negative result.

## Why execution-time structured evidence was tested

Post-hoc analysis—including a skill such as Agentic Survivor—starts from residues: the final source tree, diff, tests, and perhaps an unstructured transcript. It must infer which observations changed the plan, which constraint forced a design choice, and whether an abandoned path still appears relevant.

During execution, some of those transitions are directly observable. A harness can ask the agent to publish a concise typed checkpoint when a material hypothesis, decision, failure, revision, constraint, invariant, or validation occurs. The record can reference evidence and explicitly supersede an earlier record. That may preserve causal structure that is expensive or impossible to reconstruct confidently afterward.

Structure may also improve auditability. A renderer can apply fixed rules instead of asking another model to create an unconstrained story. Append-only storage keeps rejected and revised claims visible, while reconciliation prevents them from being presented as current truth.

This advantage is conditional. If agents record poor checkpoints, omit important transitions, rationalize decisions after the fact, or optimize for the schema, execution-time capture will not outperform post-hoc work. The final code must remain authoritative.

## Scope

The current investigation covers:

- local coding-agent sessions that expose lifecycle, tool, and extension hooks;
- compact execution metadata and explicit semantic events;
- append-only per-session persistence;
- deterministic Markdown projection;
- current-versus-superseded reconciliation;
- human evaluation of completed software changes.

The first adapter targets Pi. The research question is harness-agnostic, but portability has not been demonstrated.

No further natural-prevalence or hybrid reviewer runs are planned under the paused protocol. The two controlled runtime-rich runs and frozen packets remain part of the incomplete conditional-value pilot, but P01 must not be started and the condition key remains closed. Current product iteration occurs in the separate Agentic Survivor Skills repository and does not add observations to this experiment.

## Non-goals

This project is not intended to:

- capture or expose private chain-of-thought;
- store prompts, assistant messages, raw tool output, or credentials;
- replace code review, tests, documentation, or source inspection;
- prove that an implementation is correct;
- generate a full session replay or observability trace;
- become a general memory system for agents;
- infer developer intent with certainty;
- claim benefit from prototype existence or automated test coverage alone.

## Design commitments

1. **Source is authoritative.** Ledger claims are evidence to inspect, not truth that overrides code.
2. **Append, do not rewrite history.** Revisions supersede earlier records by ID.
3. **Render deterministically.** Identical ledger and repository state should yield identical prose structure and reconciliation.
4. **Capture less.** Store bounded metadata and declared checkpoints, not raw conversations or tool results.
5. **Make uncertainty measurable.** Divergence, omissions, false confidence, and maintenance cost are outcomes, not embarrassing edge cases.

## Falsification criteria

The main hypothesis should be rejected or materially narrowed if a sufficiently powered evaluation finds any of the following:

- no practically meaningful reduction in median time-to-understanding versus the baseline;
- lower correctness in architecture comprehension, impact prediction, or bug localization;
- higher confidence without corresponding correctness improvement;
- material ledger-to-code divergence that reviewers do not reliably detect;
- benefits limited to one task, repository, model, or highly trained participant;
- capture and maintenance costs greater than the saved comprehension time;
- post-hoc summaries perform equivalently after controlling for information and reading time;
- privacy or security risks cannot be bounded acceptably without removing the useful signal.

An inconclusive pilot is not confirmation. Results should be reported by task size, participant experience, and failure mode, including negative results.

## Current evidence

The evidence establishes feasibility, not human benefit:

- the Pi prototype records and renders the specified event forms, preserves append-only history, reconciles explicit supersession, exposes inspection commands, and passes its software tests;
- one dogfood session produced 36 execution events and no semantic events, leaving the rendered model empty;
- a later inspection session produced 82 events, including 8 semantic events, but did not implement a real change and recorded no current constraint or invariant;
- the self-contained evaluation harness can freeze a completed Pi workspace, preserve committed and untracked changes, run visible and hidden tests on copies, and build three matched review conditions;
- the `small-validation` Artifact Pipeline v1 rehearsal produced a passing implementation, 62 execution events, 2 semantic events, matched 164/182-word guides, and 10 supported audited claims; both runtime claims were post-hoc recoverable, so this small negative-control-like task contributed no runtime-unique evidence while adding 2 tool calls, 2 turns, 9,119 attributable tokens, about 15.2 seconds, and 20,213 bytes of capture artifacts;
- the `medium-atomic-reservation` run produced a passing implementation, 66 execution events, 2 semantic events, matched 195/201-word guides after one retained length retry, and 11 supported audited claims; it contributed no runtime-unique claim and recorded neither a goal nor a constraint/invariant checkpoint, so its individual Gate 1 preview fails both medium-specific checks while adding 2 tool calls, 2 turns, 10,431 attributable tokens, about 17.5 seconds, and 21,474 bytes of capture artifacts;
- the `nontrivial-idempotent-dispatch` run produced a passing implementation, 68 execution events, 2 semantic events, matched 221/232-word guides, and 11 supported audited claims; it also contributed no runtime-unique claim and recorded neither a goal nor a constraint/invariant checkpoint while adding 2 tool calls, 2 turns, 10,559 attributable tokens, about 19.8 seconds, and 22,871 bytes of capture artifacts;
- the formal three-run Artifact Pipeline v1 gate failed: all 32 audited claims were supported and the integrity, accuracy, privacy, matching, and failure-accounting checks passed, but both medium and non-trivial runs failed the runtime-unique and required-semantic-coverage checks; reviewer sessions are therefore blocked;
- the one pre-registered Instrument v2 artificial positive control passed its closure and trajectory-capture gates: closure supplied supported current semantic coverage without modifying source, and the induced failure-to-revision path yielded one audited runtime-unique review-relevant claim; the run recorded 106 execution and 8 semantic events, 56,581 attributable tokens, about $0.066 attributable cost, about $0.132 total Pi cost, and 35,528 bytes of capture artifacts; the initial invariant described the diagnostic procedure rather than the task and required one closure event; this is instrument capability evidence only;
- the fail-fast Instrument v2 natural gate stopped after its first fresh medium task: the implementation, visible tests, hidden tests, artifact integrity, closure coverage, privacy, matching, and all 8 audited claims passed, but its 4 semantic events contained only decision, validation, closure-added goal, and closure-added invariant; there was no natural causal sequence and the runtime claim was post-hoc-recoverable; capture added 4 tool calls, 4 turns, 52,328 attributable tokens, about 26 seconds, about $0.044 attributable cost, and 26,435 bytes, while total implementation-plus-closure Pi cost was about $0.120;
- before reviewer access, the hybrid conditional-value prerequisite passed on two controlled non-trivial tasks: both captured one failed path and superseding revision, and each produced one audited runtime-unique relevant claim not verifiable from final-state evidence; the two condition-masked packets were frozen; preparation used 40 model calls, 228,818 reported tokens, about 378 seconds, and about $0.468, with all artifact/audit retries retained;
- the first masked hybrid-pilot review failed at the workflow layer before conditional utility could be assessed: P02 opened 9 files, elapsed 1,420 seconds, timed out at the 1,200-second cap, recorded cognitive load 7/7, and ended without a reliable review decision because serial chat file access prevented persistent navigation and side-by-side comparison; P01 was not started and the condition key remains closed; four no-model-cost researcher command failures are also retained in the external record;
- no human-comprehension treatment effect has been measured, and the current single-reviewer study cannot estimate one.

The natural runtime-prevalence claim remains stopped. The hybrid prerequisite establishes that controlled trajectory evidence can survive the artifact and privacy gates, but the current chat-mediated reviewer workflow is unusable and yielded no conditional-value evidence. The experiment is therefore incomplete and paused, not resolved in favor of either condition. Current work moves to real-world iteration of Comprehension Sync. If research resumes, it requires a separately pre-registered interface and task protocol that preserves normal source navigation; these packets cannot be reused as fresh observations. See the [experiment protocol](experiment-protocol.md) and [roadmap](roadmap.md).
