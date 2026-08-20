# Contributing

Agent Harness Comprehension is an early research and engineering project. Contributions should help determine whether the hypothesis is useful, not assume that it is true.

## Useful contributions

- Reproducible baseline-versus-treatment trials.
- Cases where the mental model is wrong, stale, noisy, or creates false confidence.
- Privacy and security review of captured fields and persistence behavior.
- Improvements to event schemas, reconciliation, deterministic rendering, and tests.
- Reliability work required by the current Pi artifact audit and evaluation protocol.
- Better scoring rubrics or lightweight study tooling.

## Before opening a change

For a substantial proposal, open an issue describing the observed problem, the smallest useful change, and how it can be evaluated. Small documentation and test fixes can go directly to a pull request.

Keep implementation claims separate from research claims. A passing test can establish software behavior; it does not establish a human-comprehension benefit.

## Development

```sh
npm install
npm run check
```

Add tests for behavior changes. Keep ledger records bounded and structured. Preserve append-only history and deterministic rendering unless a proposal explicitly revises those invariants.

## Data and privacy

Never add prompts, assistant messages, raw tool outputs, credentials, secrets, or private chain-of-thought to the event schema, fixtures, issues, or test data. Use synthetic repositories and tasks when publishing experiment materials.

## Reporting results

Report the task, repository revision, model/configuration, participant experience, condition assignment, outcomes, exclusions, and failures. Negative and inconclusive results are welcome. Do not present a small dogfood run as general proof.

Follow the repository completion and documentation-freshness workflow in [AGENTS.md](AGENTS.md). Cross-harness adapters and broader product work remain deferred until the current evidence gates justify them.

By contributing, you agree that your contributions are licensed under the MIT License.
