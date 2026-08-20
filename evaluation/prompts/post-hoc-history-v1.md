# Post-hoc history artifact prompt v1

Using only the same frozen final-state evidence available to the current-state producer, produce a JSON document that conforms to `evaluation/schemas/post-hoc-history-v1.example.json`.

Record only decisions, revisions, or rejected paths recoverable from final evidence. Use stable `post-NNN` IDs. An empty claims array is valid when the evidence does not support history claims.
