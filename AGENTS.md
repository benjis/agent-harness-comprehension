# Repository workflow

These instructions apply to the entire repository. This is both a software project and a research record. A task is not complete until the code, experiment state, and documentation agree.

## Sources of truth

Keep each document responsible for one kind of information:

| File | Responsibility |
|---|---|
| `README.md` | Current public status, implemented capabilities, immediate next step, and links |
| `docs/research.md` | Problem, hypothesis, scope, evidence standard, and falsification criteria |
| `docs/experiment-protocol.md` | Current operational experiment and any explicitly separated future study design |
| `docs/architecture.md` | Implemented system boundary, components, data flow, invariants, and known limits |
| `docs/roadmap.md` | Evidence-gated next work; no duplicated implementation or protocol detail |
| `evaluation/README.md` | Commands and artifacts for running the current evaluation harness |

Source code, frozen repositories, tests, and observed runtime behavior are authoritative for implementation facts. Research artifacts may explain evidence but never override it.

## Work cycle

For every repository-changing task:

1. Inspect `git status` and preserve unrelated user changes.
2. Read the relevant source, tests, and source-of-truth documents before editing.
3. Make the smallest coherent change that advances the current research gate.
4. Add or update tests in proportion to the change.
5. Run `npm run check` unless the task cannot affect executable or evaluation behavior; document any narrower validation.
6. Perform the documentation freshness audit below.
7. Inspect the complete diff and repository status.
8. Selectively stage only the coherent task changes.
9. Automatically create a commit unless the user said not to commit or the worktree contains overlapping changes that cannot be safely separated.
10. Report the commit hash, summary, validation, and any remaining work. Do not push, tag, publish, or release unless the user explicitly requests it.

Read-only analysis, questions, and reviews do not require a commit.

## Automatic commit policy

Use one commit for one coherent completed task. Split commits only when the pieces are independently reviewable and releasable. Never amend, squash, rebase, or rewrite an existing commit unless the user asks.

Use this message shape:

```text
<type>: <concise outcome>

Summary:
- <material result>
- <material result>

Validation:
- <command and result>
```

Choose a conventional type such as `feat`, `fix`, `docs`, `test`, `refactor`, or `chore`. The final user-facing summary should match the commit body rather than introducing a different account of the work.

If the worktree was already dirty, stage explicit paths. Do not include unrelated modifications, generated secrets, local run artifacts, or another person's work merely to make the tree clean. If a safe task-only commit is not possible, leave the changes uncommitted and explain why.

## Documentation freshness audit

Run this audit before every automatic commit:

1. Compare the changed behavior and research state with the sources-of-truth table.
2. Update `README.md` when current status, supported commands, prerequisites, or the immediate next step changed.
3. Update `docs/architecture.md` only for implemented boundaries, flows, invariants, data handling, or known limits.
4. Update `docs/experiment-protocol.md` when conditions, tasks, measurements, gates, exclusions, or study interpretation changed.
5. Update `docs/research.md` when the hypothesis, evidence, scope, or falsification interpretation changed.
6. Update `docs/roadmap.md` when a gate was completed, blocked, reordered, narrowed, or invalidated.
7. Update `evaluation/README.md` when evaluation commands, inputs, outputs, or limitations changed.
8. Search for old filenames, obsolete status claims, superseded commands, broken relative links, and conflicting numbers or conditions.

Do not update every document mechanically. Update only the document that owns the changed fact, then link to it elsewhere.

### Merge and deletion rules

- Prefer stable topic filenames such as `experiment-protocol.md`; keep protocol or schema versions inside the document.
- Merge documents when they serve the same audience and repeatedly restate the same facts.
- Delete a document when its still-valid content has been moved to the owning document and all links have been updated.
- Keep historical decisions only when they explain a current constraint or result. Git history is the archive for superseded prose.
- Do not retain an outdated document merely because it once contained useful thinking.
- Do not rewrite negative results into success narratives. Preserve failed runs and protocol deviations in the current research record where they remain relevant.

## Research integrity

- Distinguish feasibility evidence, formative observations, and efficacy evidence.
- The current single-reviewer study is formative and cannot establish a treatment effect.
- Keep ordinary, post-hoc, and runtime-enhanced conditions tied to the same frozen implementation.
- Keep hidden tests, private rubrics, researcher keys, and Pi sessions out of reviewer packets.
- Record missing ledgers, invalid guides, capture failures, and privacy rejections as costs; never silently exclude them.
- Do not capture or request private chain-of-thought.
- Pre-register material changes to conditions, gates, word budgets, or scoring before inspecting outcomes.

## Repository hygiene

- Do not commit `.pi/` session artifacts, researcher-owned run directories, credentials, dependencies, coverage, or build output.
- Keep reusable evaluation fixtures and harness code under `evaluation/`; keep individual study runs outside the repository.
- Use relative links in repository Markdown and verify renamed or deleted targets before committing.
- Prefer deleting superseded generated prose over maintaining parallel versions.

## Definition of done

A repository-changing task is complete when:

- requested behavior or research material is implemented;
- relevant automated checks pass;
- documentation reflects the same current state without contradictory duplicates;
- the diff contains no unrelated changes or accidental artifacts;
- a task commit exists under the automatic commit policy, unless a documented exception applies;
- no required push or release is implied by the commit itself.
