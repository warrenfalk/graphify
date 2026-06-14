**Step B2 - Dispatch subagents in bounded batches (Codex)**

> **Codex platform:** Uses `spawn_agent` + `wait_agent` + `close_agent` instead of the Agent tool.
> Requires `multi_agent = true` under `[features]` in `~/.codex/config.toml`.
> If `spawn_agent` is unavailable, tell the user to add that config and restart Codex.

Semantic mode distinction:
- **Standalone CLI:** `graphify extract INPUT_PATH` runs inside the installed graphify package. Semantic extraction uses installed backend SDKs plus provider credentials; it cannot call Codex subagents.
- **Codex skill:** this skill may use `spawn_agent` for semantic extraction, so it can process docs/papers/images without separate graphify API keys. That is a Codex runtime capability, not a standalone CLI feature.
- For a local keyless CLI graph, run `graphify extract INPUT_PATH --local-only --no-viz`; use `graphify update INPUT_PATH --no-viz` for existing graphs.

Load `graphify-out/.graphify_chunks.json` and process it in bounded batches. Default to `CODEX_AGENT_BATCH_SIZE = 6`; lower it if `spawn_agent` reports a thread-limit error. Never try to spawn every chunk at once.

Codex workers must write results as durable files, not return JSON inline. For chunk N, derive an absolute `CHUNK_PATH` under the current project root, e.g. `${PROJECT_ROOT}/graphify-out/.graphify_chunk_NN.json`. The worker writes the full JSON there; its final chat response must be a short status line only, with counts, and must never include the full JSON payload.

For each batch:
1. Call `spawn_agent` once per chunk in the batch, in the same response, so only that batch runs in parallel.
2. If any `spawn_agent` call fails with a thread-limit error, immediately wait/close every worker that was already spawned in that batch, lower the batch size, and retry the failed and remaining chunks. Do not abandon already-started workers without closing them.
3. After the batch is spawned, collect every result with `wait_agent(handle)` and always call `close_agent(handle)`.
4. Parse and accumulate the batch results before spawning the next batch.

Build each worker message by wrapping the extraction prompt in task-delegation framing:

```
spawn_agent(agent_type="worker", message="Your task is to perform the following. Follow the instructions below exactly.\n\n<agent-instructions>\n[extraction prompt, with FILE_LIST, CHUNK_NUM, TOTAL_CHUNKS, and DEEP_MODE substituted]\n\nCodex handoff override: do NOT return the JSON in chat. Validate that your extraction is valid JSON with top-level nodes, edges, hyperedges, input_tokens, and output_tokens. Write it atomically to CHUNK_PATH: write a temporary file next to CHUNK_PATH, then rename it to CHUNK_PATH. Your final response must be only: wrote CHUNK_NUM to CHUNK_PATH with N nodes, E edges, H hyperedges.\n</agent-instructions>\n\nExecute this now.")
```

For each spawned handle, collect results sequentially in memory before starting the next batch:
```
result = wait_agent(handle); close_agent(handle)   # repeat per handle; result should be a short status, not JSON
```

Do not parse worker chat responses as JSON. Step B3 reads and validates the `graphify-out/.graphify_chunk_NN.json` files from disk. If a worker returns full JSON inline, ignore that inline payload and require the chunk file.

Subagent prompt template:

See `references/extraction-spec.md` for the compact subagent prompt (rules, node-ID format, confidence rubric, hyperedge and vision rules, JSON schema). Load it only here, only when at least one chunk holds a doc, paper, or image; a pure-code corpus has skipped Part B and never reads it. Pass each agent that prompt verbatim with FILE_LIST, CHUNK_NUM, TOTAL_CHUNKS, DEEP_MODE, and CHUNK_PATH substituted, plus the Codex handoff override above so the worker writes CHUNK_PATH and returns only a short status.
