# Conditional-value pilot: rollback trajectory v1

This is a researcher-only implementation instruction. Complete the public task in `TASK.md`, but use this one bounded first attempt so the pilot has an observable trajectory:

1. Record a concise `hypothesis` checkpoint that one rescue around the whole dispatch body can release the shipment quantities after any dispatch failure.
2. Implement that boundary as the first attempt.
3. Add and run a focused visible test proving that a reservation failure must leave unavailable stock unchanged. The first attempt must remain visible in the session and is expected to fail because it compensates a reservation that never completed.
4. Record the observed assertion as a `failure` checkpoint.
5. Record a `revision` checkpoint that supersedes the hypothesis, then narrow compensation to failures after reservation has completed and finish the public task normally.
6. Run the visible suite and stop.

Do not induce a second failed path. Do not run a closure prompt. Do not access hidden tests or private rubrics. Record only concise claims and observable references; do not record private chain-of-thought, raw prompts, secrets, or raw tool output.
