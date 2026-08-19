# Agent Harness Comprehension

An experimental comprehension layer for coding agents. It records small, structured checkpoints while an agent works, keeps them in an append-only ledger, and deterministically renders a mental model that separates current conclusions from superseded history.

The project investigates **comprehension debt**: the gap between how quickly software can be changed by an agent and how quickly a human can build an accurate, usable model of that change.

> **Project status: early prototype and dogfood study.** The Pi extension, JSONL ledger, reconciliation rules, renderer, commands, and automated tests exist. The central claim—that this approach improves human understanding over ordinary code, diffs, and summaries—has not yet been proven. The next step is controlled evaluation, not broader claims.

## Motivation from engineering conversations

Recent informal interviews by the project author with engineering leaders and developers across several companies surfaced a repeated theme: agentic coding has increased implementation productivity, but the bottleneck is moving to human understanding. Agent-produced changes can be harder to review, even though a human still decides whether to accept them and remains responsible for the result.

This suggests an important distinction: putting a human **in the decision loop** does not necessarily put them **in the understanding loop**. A person may approve an agent's recommendation without the mental model needed to judge its assumptions, consequences, or failure modes. These conversations motivate the research question; they are qualitative observations, not controlled evidence that this project solves the problem.

## Research documents

- [Thesis and research note](docs/thesis-or-research-note.md) — the comprehension-debt problem, hypothesis, scope, non-goals, and falsification criteria.
- [Experiment plan](docs/experiment-plan.md) — baseline-versus-treatment methodology, measurements, scoring, and threats to validity.
- [Architecture](docs/architecture.md) — event flow, ledger, deterministic reconciliation, commands, and data boundary.
- [Roadmap](docs/roadmap.md) — current prototype status and evidence-gated milestones.

## Why move comprehension into the harness?

This work began with [The Agentic Survivor Skills](https://github.com/benjis/The-Agentic-Survivor-Skills), a skill-level attempt to reconstruct a useful mental model after an agent produced a solution. That approach remains useful, but it exposed a structural limit: post-hoc inspection often sees the final path while losing the causal relationships that shaped it—especially failed attempts, revised hypotheses, and alternatives that were rejected for a reason.

Earlier experiments integrated comprehension into DeepSeek Harness. The current prototype uses Pi's native extension and lifecycle hooks to test the same idea with a smaller event-ledger design. The goal is not to make one skill larger. It is to test whether comprehension should be a first-class harness responsibility, with evidence captured while causal transitions are still observable.

## The idea in one minute

Most explanations of agent-generated code are produced after implementation. They reconstruct intent from the final code, diff, or transcript. This project tests a different idea: a coding-agent harness can capture concise, typed, decision-relevant evidence at the moment a hypothesis changes, a constraint is discovered, a decision is made, or a validation succeeds.

```text
coding-agent lifecycle and tool events
                │
                ▼
structured execution + semantic comprehension events
                │
                ▼
       append-only JSONL ledger
                │
                ▼
 deterministic mental-model renderer
                │
                ▼
 current truth + superseded/history reconciliation
                │
                ▼
       /comprehension and /comprehension-status
```

This is a hypothesis, not a conclusion. Execution-time capture could preserve useful context that is expensive to infer later. It could also add noise, cost, or false confidence. The [experiment plan](docs/experiment-plan.md) is designed to distinguish those outcomes.

## What exists today

- A working [Pi coding-agent](https://github.com/earendil-works/pi) extension.
- Automatic compact lifecycle and tool metadata events.
- An LLM-callable `record_comprehension_event` tool for typed semantic checkpoints: goals, hypotheses, evidence, decisions, alternatives, failures, revisions, constraints, tradeoffs, invariants, and validations.
- An append-only `events.jsonl` ledger with referenceable event IDs.
- Explicit supersession: later events can replace earlier conclusions without deleting history.
- A deterministic Markdown renderer that separates current truth from historical, refuted, or superseded records.
- `/comprehension` and `/comprehension-status` commands.
- Tests for schema validation, append-only behavior, reconciliation, lifecycle capture, and tool registration.

The prototype deliberately does **not** capture prompts, assistant messages, raw tool outputs, credentials, or private chain-of-thought. It records compact metadata and explicitly published conclusions. Source code remains authoritative.

## Try the prototype

Requirements: Node.js 22.19 or newer and Pi 0.84.x.

```sh
npm install
npm run check
pi -e ./src/index.ts
```

During a session:

- `/comprehension` renders the current mental model.
- `/comprehension-status` shows event counts, artifact paths, and persistence errors.

Artifacts are local to the target project:

```text
.pi/comprehension/<session-id>/events.jsonl
.pi/comprehension/<session-id>/mental-model.md
```

The extension uses the host agent's normal model configuration. Do not use the prototype on sensitive repositories until you have reviewed the [security and data boundary](docs/architecture.md#data-boundary).

## Research questions

1. Does structured execution-time evidence reduce time-to-understanding without reducing correctness?
2. Does it improve architecture comprehension, impact prediction, and bug localization?
3. Does user confidence track correctness more closely, or does the artifact create false confidence?
4. How often does the rendered model diverge from the final code?
5. Is the benefit worth the capture, model, storage, and maintenance cost?
6. Does it help reviewers justify an approval or rejection from an accurate mental model rather than relying on the agent's recommendation?

Read the [research note](docs/thesis-or-research-note.md), [architecture](docs/architecture.md), [experiment plan](docs/experiment-plan.md), and [roadmap](docs/roadmap.md).

## Why sustained Codex and API use matters to this work

The hypothesis can only be tested across many real implementation sessions, models, repositories, and task sizes. Sustained Codex use would supply realistic agent-generated changes for dogfooding; API access would support repeatable treatment generation, ablations, and evaluation runs under controlled model settings. That would make it possible to measure whether the comprehension layer transfers across tasks instead of optimizing it around a few hand-picked examples.

## Contributing

This project needs skeptical contributions: counterexamples, measurement design, privacy review, portability work, and small reproducible trials are as valuable as implementation changes. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).
