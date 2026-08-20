# Runtime history artifact prompt v1

Using the frozen final-state evidence plus the captured runtime ledger, produce a JSON document that conforms to `evaluation/schemas/runtime-history-v1.example.json`.

Use stable `run-NNN` IDs. Runtime citations must use `runtime:<event-id>` and refer to an event present in the ledger. Do not include private chain-of-thought, hidden tests, or claims unsupported by cited evidence.
