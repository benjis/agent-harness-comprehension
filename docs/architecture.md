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

## Evaluation boundary

The Ruby evaluation harness is separate from the Pi runtime extension. It imports a completed Pi workspace after the agent has settled; it does not drive the agent or mutate the treatment while implementation is running.

```text
prepared ParcelFlow workspace
           │ Pi + extension
           ▼
completed workspace + session ledger
           │ import and drift check
           ▼
 frozen run directory
 task + repository + diff + visible tests
 researcher-only ledger + hidden tests
           │ validate artifacts + render matched guides
           ▼
 claim audit + three-run Gate 1
           │ pass only
           ▼
 O / P / R review packets
           │ condition-masked review
           ▼
 formative session and score records
```

The classes under `evaluation/lib/` own this boundary:

- `ProjectFactory` creates a clean, committed task baseline without private rubrics or hidden tests.
- `RunImporter` resolves the fixture's root commit as the baseline, captures committed and untracked changes, excludes `.git`, `.pi`, and `.comprehension` from reviewer source, fingerprints the source before and after import, and rejects drift.
- Visible and hidden tests run on separate copies of the frozen repository. Hidden results remain researcher-only and do not determine trial eligibility.
- `ArtifactPipeline` validates versioned current-state, P-history, R-history, and generation-metadata contracts. It checks cited final files and runtime event IDs, records provenance hashes and costs, and deterministically renders both guides from one shared current-state model.
- `ClaimAuditor` requires an audit row for every generated claim. `FormativeGate` re-derives provenance hashes and both guides, evaluates one small, medium, and non-trivial run together, and is the only component that can mark those runs eligible.
- `PacketBuilder` gives every condition the same task, repository, diff, and visible tests. P and R each receive one identically named `review-guide.md`; O receives no guide.
- `FormativeAssignmentBuilder`, `ReviewSession`, and `ResultAnalyzer` record the current one-reviewer workflow and explicitly prevent a causal or release decision.

Individual workspaces and run directories stay outside the repository. The reusable fixture, private task material, runner, and tests live under `evaluation/`. No earlier DSH repository or runtime is required.

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
- Import-time fingerprints detect local source drift during the evidence cut but do not control remote writers or prove general task settlement.
- Artifact content still depends on an external model invocation; the harness validates structured outputs and renders Markdown but does not call a model provider.
- Claim support classifications are researcher-produced inputs. The harness enforces completeness and the pre-registered gate logic, not the truth of the auditor's judgment.
- The current evaluation has one reviewer and produces formative case evidence only.
