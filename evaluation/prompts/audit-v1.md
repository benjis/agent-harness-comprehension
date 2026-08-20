# Claim-audit prompt v1

Audit every claim from the current-state, post-hoc history, and runtime history artifacts against the frozen evidence cut. Produce one row per claim and no extra rows using `evaluation/schemas/claim-audit-v1.example.json`.

Treat missing, stale, contradicted, privacy-rejected, capture-failed, and renderer-failed evidence as measured costs. Do not silently omit failures or reinterpret formative evidence as an efficacy result.
