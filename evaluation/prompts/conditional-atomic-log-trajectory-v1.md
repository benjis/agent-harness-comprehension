# Conditional-value pilot: atomic-log trajectory v1

This is a researcher-only implementation instruction. Complete the public task in `TASK.md`, but use this one bounded first attempt so the pilot has an observable trajectory:

1. Record a concise `hypothesis` checkpoint that the existing direct overwrite remains sufficient when append serialization is prepared completely before `File.write`.
2. Keep direct overwrite as the first attempt.
3. Add and run a focused visible test that injects a partial write followed by `IOError` and expects the prior log bytes to survive. The first attempt must remain visible in the session and is expected to fail because the destination was already truncated.
4. Record the observed assertion as a `failure` checkpoint.
5. Record a `revision` checkpoint that supersedes the hypothesis, then implement same-directory temporary-file replacement and cleanup as required by the public task.
6. Run the visible suite and stop.

Do not induce a second failed path. Do not run a closure prompt. Do not access hidden tests or private rubrics. Record only concise claims and observable references; do not record private chain-of-thought, raw prompts, secrets, or raw tool output.
