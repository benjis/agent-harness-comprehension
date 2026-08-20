# Agent Harness Comprehension

An experimental comprehension layer for coding agents. It records small, structured checkpoints while an agent works, keeps them in an append-only ledger, and deterministically renders current conclusions separately from superseded history.

The project investigates **comprehension debt**: the gap between how quickly software can be changed by an agent and how quickly a human can build an accurate, usable model of that change.

> **Current status: Gate 1 failed.** All three Artifact Pipeline v1 runs and claim audits are complete. Neither the medium nor non-trivial run produced a runtime-unique review-relevant claim, and both missed required goal and constraint/invariant coverage. Reviewer sessions remain blocked; no controlled evidence shows that execution-time capture improves human understanding.

## Current research step

The immediate question is narrower than “does a comprehension summary help?”:

> Does runtime capture preserve reliable, review-relevant causal information that cannot be recovered with equivalent confidence from the frozen task, repository, diff, and tests?

The current study uses three ParcelFlow Ruby tasks and three matched review conditions:

- ordinary review materials;
- a post-hoc guide generated only from frozen final-state evidence;
- a runtime-enhanced guide using the same final-state model plus eligible semantic checkpoints.

Only one reviewer is currently available. The immediate next decision is whether to use the protocol's one bounded capture redesign under a new instrument version or pivot to simpler post-hoc evidence generation. Do not begin the formative self-study unless a future repeated Gate 1 passes.

## What exists

- A Pi coding-agent extension built on public lifecycle, tool, and command APIs.
- Compact automatic execution events and an LLM-callable `record_comprehension_event` tool.
- Typed semantic checkpoints for goals, hypotheses, evidence, decisions, alternatives, failures, revisions, constraints, tradeoffs, invariants, and validations.
- An append-only per-session `events.jsonl` ledger with stable IDs and explicit supersession.
- A deterministic `mental-model.md` renderer plus `/comprehension` and `/comprehension-status`.
- Focused TypeScript tests for schema, persistence, reconciliation, rendering, and extension behavior.
- A DSH-independent Ruby evaluation harness that prepares ParcelFlow tasks, imports completed Pi runs, freezes tracked and untracked changes, validates structured artifacts, deterministically renders matched guides, audits every claim, enforces Gate 1, builds condition-masked packets, records review sessions, and produces formative analysis.

The prototype does **not** capture prompts, assistant messages, raw tool outputs, credentials, or private chain-of-thought. Source code and observed behavior remain authoritative.

## Repository guide

- [Research](docs/research.md) — problem, hypothesis, evidence standard, scope, and falsification criteria.
- [Experiment protocol](docs/experiment-protocol.md) — operational artifact audit, matched conditions, single-reviewer procedure, and future efficacy-study requirements.
- [Architecture](docs/architecture.md) — implemented Pi event flow, ledger, reconciliation, commands, and data boundary.
- [Roadmap](docs/roadmap.md) — the current evidence gate and what is deliberately deferred.
- [Evaluation harness](evaluation/README.md) — self-contained Ruby tasks and study commands.
- [Repository workflow](AGENTS.md) — automatic commit, documentation freshness, and research-integrity rules.

## Try the Pi prototype

Requirements: Node.js 24.19 or newer and Pi 0.84.x.

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

Do not use the prototype on sensitive repositories until reviewing the [security and data boundary](docs/architecture.md#data-boundary).

## Run the evaluation checks

The evaluation uses Ruby's standard library and Git; it does not require DeepSeek Harness or the earlier DSH experiment repositories.

```sh
npm run test:evaluation
```

See the [evaluation guide](evaluation/README.md) before preparing a real task workspace. Keep individual workspaces, Pi sessions, run directories, hidden results, and reviewer data outside this repository.

## Experimental lineage

The work began with Agentic Survivor, a post-hoc skill for revision-pinned code-reading editions. That experiment established useful evidence discipline but could not reliably recover failed paths or causal revisions from final code alone. Later DeepSeek Harness experiments explored a post-settlement evidence package. The current Pi prototype isolates the execution-time capture hypothesis with a smaller event ledger.

These predecessors explain the research direction; neither is a runtime dependency of this repository.

## Contributing

Skeptical contributions are welcome: counterexamples, measurement design, privacy review, portability work, and reproducible negative results are as valuable as feature work. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).
