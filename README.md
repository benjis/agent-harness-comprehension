# Agent Harness Comprehension

An experimental comprehension layer for coding agents. It records small, structured checkpoints while an agent works, keeps them in an append-only ledger, and deterministically renders current conclusions separately from superseded history.

The project investigates **comprehension debt**: the gap between how quickly software can be changed by an agent and how quickly a human can build an accurate, usable model of that change.

> **Current status: the human-comprehension experiment is incomplete and paused.** The artifact gate passed, but the first masked review timed out and ended without a reliable review decision because chat-mediated file access prevented persistent navigation and side-by-side source comparison. P01 was not started, the researcher key remains closed, and no condition-level or efficacy result was produced.

## Current direction

The research prototype and frozen external runs remain a record of feasibility, negative prevalence results, controlled trajectory capture, cost, and reviewer-workflow failure. They do not establish that runtime or post-hoc artifacts improve human comprehension.

The immediate work has moved to product iteration in the separate Agentic Survivor Skills repository. Its `comprehension-sync` skill keeps a human and coding agent aligned during real changes through thin slices, consequential-decision pauses, direct source access, and mental-model handoffs. This direction was motivated by the formative failure observed here; it is not a validated treatment result.

The superseded runtime study used three matched conditions:

- ordinary review materials;
- a post-hoc guide generated only from frozen final-state evidence;
- a runtime-enhanced guide using the same final-state model plus eligible semantic checkpoints.

Only one reviewer is currently available. P02 opened 9 files, elapsed 1,420 seconds, hit the 1,200-second cap, recorded cognitive load 7/7, and produced no reliable approve/reject decision. This is a workflow result, not evidence for either masked condition. Do not start P01, open the researcher key, or treat the frozen packets as fresh observations. Any future human study requires a separately pre-registered protocol with normal persistent source navigation.

## What exists

- A Pi coding-agent extension built on public lifecycle, tool, and command APIs.
- Compact automatic execution events and an LLM-callable `record_comprehension_event` tool.
- Typed semantic checkpoints for goals, hypotheses, evidence, decisions, alternatives, failures, revisions, constraints, tradeoffs, invariants, and validations.
- An append-only per-session `events.jsonl` ledger with stable IDs and explicit supersession.
- A deterministic `mental-model.md` renderer plus `/comprehension` and `/comprehension-status`.
- Focused TypeScript tests for schema, persistence, reconciliation, rendering, and extension behavior.
- A DSH-independent Ruby evaluation harness that prepares ParcelFlow tasks, imports completed Pi runs, freezes tracked and untracked changes, validates structured artifacts, deterministically renders matched guides, audits every claim, evaluates the historical gates and the hybrid conditional-value gate, builds condition-masked packets, records review sessions, and produces formative analysis.

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

The work began with Agentic Survivor's revision-pinned Code Reading skill. That work established useful evidence discipline but could not reliably recover failed paths or causal revisions from final code alone. Later DeepSeek Harness experiments explored a post-settlement evidence package, and the Pi prototype isolated the execution-time capture hypothesis with a smaller event ledger. Agentic Survivor now also contains Comprehension Sync, a live human-agent collaboration workflow informed by this project's formative observations.

These related projects explain the product and research lineage; none is a runtime dependency of this repository, and the existence of the new skill does not complete this experiment.

## Contributing

Skeptical contributions are welcome: counterexamples, measurement design, privacy review, portability work, and reproducible negative results are as valuable as feature work. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).
