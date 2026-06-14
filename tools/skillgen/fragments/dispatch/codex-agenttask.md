**Step B2 - Dispatch subagents in bounded batches (Codex)**

> **Codex platform:** Uses `spawn_agent` + `wait_agent` + `close_agent` instead of the Agent tool.
> Requires `multi_agent = true` under `[features]` in `~/.codex/config.toml`.
> If `spawn_agent` is unavailable, tell the user to add that config and restart Codex.

Semantic mode distinction:
- **Standalone CLI:** `graphify extract INPUT_PATH` runs inside the installed graphify package. Semantic extraction uses installed backend SDKs plus provider credentials; it cannot call Codex subagents.
- **Codex skill:** this skill may use `spawn_agent` for semantic extraction, so it can process docs/papers/images without separate graphify API keys. That is a Codex runtime capability, not a standalone CLI feature.
- For a local keyless CLI graph, run `graphify extract INPUT_PATH --local-only --no-viz`; use `graphify update INPUT_PATH --no-viz` for existing graphs.

Load `graphify-out/.graphify_chunk_plan.json` and process it in bounded batches. Default to `CODEX_AGENT_BATCH_SIZE = 6`; lower it if `spawn_agent` reports a thread-limit error. Never try to spawn every chunk at once.

For each batch:
1. Call `spawn_agent` once per chunk in the batch, in the same response, so only that batch runs in parallel.
2. If any `spawn_agent` call fails with a thread-limit error, immediately wait/close every worker that was already spawned in that batch, lower the batch size, and retry the failed and remaining chunks. Do not abandon already-started workers without closing them.
3. After the batch is spawned, collect every result with `wait_agent(handle)` and always call `close_agent(handle)`.
4. Parse and accumulate the batch results before spawning the next batch.

Build each worker message by wrapping the extraction prompt in task-delegation framing:

```
spawn_agent(agent_type="worker", message="Your task is to perform the following. Follow the instructions below exactly.\n\n<agent-instructions>\n[extraction prompt, with FILE_LIST, CHUNK_NUM, TOTAL_CHUNKS, DEEP_MODE substituted]\n</agent-instructions>\n\nExecute this now. Output ONLY the structured JSON response.")
```

For each spawned handle, collect results sequentially in memory before starting the next batch:
```
result = wait_agent(handle); close_agent(handle)   # repeat per handle
```

Parse each result as JSON. Accumulate nodes/edges/hyperedges across all results and write to `graphify-out/.graphify_semantic_new.json`. Codex collects in memory, so there are no per-chunk files on disk; the disk-based success checks in Step B3 do not apply — a chunk that returns invalid JSON is the failure signal instead.

Subagent prompt template:

See `references/extraction-spec.md` for the compact subagent prompt (rules, node-ID format, confidence rubric, hyperedge and vision rules, JSON schema). Load it only here, only when at least one chunk holds a doc, paper, or image; a pure-code corpus has skipped Part B and never reads it. Pass each agent that prompt verbatim with FILE_LIST, CHUNK_NUM, TOTAL_CHUNKS, and DEEP_MODE substituted, and have it return the JSON inline.
