# Architecture

## System boundary

The prototype is a Pi coding-agent extension. It observes public harness lifecycle and tool events, registers one constrained semantic-event tool, persists a per-session ledger, and renders a local Markdown artifact.

```text
Pi lifecycle/tool hooks
        │ automatic, compact metadata
        ├──────────────────────────────┐
        │                              │
        │                    record_comprehension_event
        │                    explicit typed checkpoints
        │                              │
        └──────────────┬───────────────┘
                       ▼
             ComprehensionLedger
          append-only events.jsonl
                       │
                       ▼
          deterministic reconciliation
       active/confirmed vs refuted/superseded
                       │
                       ▼
              mental-model.md
                       │
              ┌────────┴────────┐
              ▼                 ▼
      /comprehension   /comprehension-status
```

## Components

### Harness adapter (`src/extension.ts`)

Subscribes to session, agent, turn, and tool lifecycle events. It records event type, timestamp, stable IDs, short summaries, and bounded metadata such as tool name, call ID, turn index, and an optional target path. It does not retain tool result bodies.

The adapter registers `record_comprehension_event`, whose schema accepts a concise semantic event plus optional reasons, evidence references, superseded IDs, related files, and related symbols. Events are sequentially written so ledger order matches accepted append order.

### Event model (`src/types.ts`)

There are two event families:

- **Execution events** describe observable harness transitions: session/agent/turn lifecycle and tool start/completion/failure.
- **Semantic events** contain explicitly published conclusions or transitions: goal, hypothesis, evidence, decision, alternative, failure, revision, constraint, tradeoff, invariant, or validation.

Semantic status is one of `active`, `confirmed`, `refuted`, or `superseded`. IDs make records referenceable. Text is normalized and schema fields are bounded.

### Append-only ledger (`src/ledger.ts`)

`ComprehensionLedger` serializes each event as one JSON line. Writes are queued within the process to preserve order. Existing records are never updated in place. Read failures are surfaced through status while malformed historical lines are skipped.

The current prototype does not provide cross-process file locking, cryptographic integrity, schema migration, or crash recovery beyond newline-delimited append behavior. Those limits matter if the adapter moves beyond single-session dogfooding.

### Reconciliation and renderer (`src/renderer.ts`)

Reconciliation is deterministic:

1. Collect semantic event IDs named by later `supersedes` fields.
2. Treat explicitly `refuted` or `superseded` events, and referenced earlier events, as non-current.
3. Group current events into goal, implementation, decisions, constraints/invariants, and validation.
4. Keep rejected, failed, and superseded records in a historical section.
5. Resolve current file references at render time and list symbol anchors.

The renderer performs no model call. The same ordered ledger and filesystem state produce the same Markdown structure and content.

### User commands

- `/comprehension` waits for the agent to become idle, renders `mental-model.md`, and reports its location.
- `/comprehension-status` reports event counts, ledger and artifact paths, and the last persistence or rendering error.

The renderer also runs when the agent settles and during session shutdown.

## Data flow

1. `session_start` creates `.pi/comprehension/<session-id>/`.
2. Lifecycle and tool hooks append execution events.
3. The agent uses `record_comprehension_event` only for material semantic checkpoints.
4. Every accepted event is appended to `events.jsonl`.
5. Settlement, shutdown, or `/comprehension` reads the ledger and rewrites `mental-model.md`.
6. Superseded records remain auditable but are excluded from current truth.

## Data boundary

The comprehension layer explicitly does **not** capture:

- user or system prompts;
- assistant messages;
- raw tool arguments beyond an optional target path;
- raw tool outputs or error bodies;
- credentials, tokens, or secrets;
- private chain-of-thought or hidden reasoning.

The semantic tool instructions also prohibit those contents. This is a design boundary, not a complete data-loss-prevention system: an agent could still place sensitive text in an allowed semantic string or file reference. The prototype should therefore be treated as experimental, artifacts should remain local by default, and sensitive repositories require review before use.

## Invariants

- Ledger writes append; earlier valid records are not mutated by normal operation.
- A later event may supersede an earlier ID, but history remains inspectable.
- Execution event capture never persists raw tool result bodies.
- The mental model is a deterministic projection, not a second model's interpretation.
- Ledger claims never override final source, tests, or runtime behavior.
- Persistence failure does not block the coding task; it is reported through status.

## Known architectural limits

- The semantic checkpoint quality depends on the implementation agent.
- Supersession is explicit; contradictory events without links may both appear current.
- File existence is checked, but claims are not automatically verified against source content.
- The current storage model assumes one extension process writes a session ledger.
- Retention, redaction, migrations, integrity checks, and multi-harness schemas remain future work.
- The Pi adapter demonstrates feasibility, not harness portability.

