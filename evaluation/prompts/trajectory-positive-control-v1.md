# Instrument v2 trajectory positive control

This is a researcher-only diagnostic instruction. Complete the public task in `TASK.md`, but use the following bounded path exactly once so the capture instrument can be tested against an observable revision:

1. Before editing, record concise `goal` and `invariant` or `constraint` checkpoints for the public task.
2. Record a `hypothesis` that Dispatcher instance-local state can provide retry idempotency, then implement that approach as the first attempt.
3. Add the public cross-instance retry test and run the focused visible test once. The instance-local approach is expected to fail because a new Dispatcher cannot see the first instance's state.
4. Record the observed test failure as a `failure` checkpoint. Do not conceal or delete the failed attempt from the session history.
5. Record a `revision` that supersedes the hypothesis, then correct the implementation normally by using shared `DispatchLog` state.
6. Record the final `decision` and `validation` checkpoints, including observable file or test references.

Do not induce a second failed path. Do not access hidden tests or private rubrics. Keep checkpoint summaries concise and do not record private chain-of-thought, raw prompts, secrets, or raw tool output.
