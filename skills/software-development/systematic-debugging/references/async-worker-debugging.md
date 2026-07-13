# Debugging Async Worker / Queued-Command Architectures

Systems where work is queued as database records and processed asynchronously by a background worker (e.g. embedding pipelines, CI queues, job schedulers). Key distinction from regular bugs: the "apparent state" (command statuses) can differ meaningfully from the "actual state" (stored data).

## Core Pattern: Stale Pending Commands

The most common pitfall: old commands queued during a prior (misconfigured) state remain in the database as `pending` or `failed`, making it look like the worker is broken when it's actually idle, waiting for fresh commands.

### Investigation Flow

1. **Map the architecture**
   ```
   What submits work?  →  What stores it?  →  What consumes it?  →  Where is the result?
   (API endpoint)         (DB table)           (worker process)       (output table)
   ```
   Identify each layer before tracing a single command.

2. **Check what the worker actually did** (not what the command table says)
   ```sql
   -- Count completed vs pending vs failed
   SELECT status, count() GROUP BY status
   
   -- Check the OUTPUT table, not the command table
   SELECT count() FROM source_embedding WHERE source = $source_id
   ```
   In the Open Notebook case: 125 commands existed (41 completed, 42 pending, 42 failed) — but the `source_embedding` table held all 339 chunks. The pending/failed were **stale duplicates**, not real blockers.

3. **Verify the worker is alive independently**
   ```bash
   # Check process
   ps aux | grep worker
   
   # Check it's actually polling
   strace -p <PID> -e epoll_wait  # docker exec may limit this
   /proc/<PID>/status              # check state
   
   # Check logs — worker may have emitted the real error inside container logs
   docker logs <container> | grep -i "error\|traceback\|embed"
   ```

4. **When the worker processed some but not all commands**
   - Commands queued with an invalid config before you fixed it → they'll stay pending forever
   - The worker isn't "stuck" — it just finished its work and the remaining commands use a stale execution context
   - **Fix: submit fresh commands via the API rather than injecting into the DB**
     ```python
     # Don't write to the command table directly
     POST /api/embeddings/rebuild {"notebook_id": "...", "mode": "all"}
     ```
   - The API creates properly-formed `CommandModel` objects with the right `execution_context`

### Red Flags

| Observation | Likely Cause |
|---|---|
| Worker `do_epoll_wait` / sleeping | Normal idle state — no commands to process |
| Pending commands > 0 but worker idle | Stale commands from earlier broken config |
| "Failed" commands but data exists in output table | Old failures from before config was fixed |
| Direct function call fails (e.g. `embed_source_command`) | Missing `execution_context` — only the worker injects this |

### What NOT to Do

- ❌ **Don't try to delete/fail stale pending commands in the DB** — the worker may not reset its state, and the data is harmless. Just submit fresh ones.
- ❌ **Don't call `embed_source_command` directly** — it needs `execution_context` that only the worker provides. Use the API rebuild endpoint instead.
- ❌ **Don't restart the worker** — it's not broken, it just has nothing compatible to process.

### The Right Fix Sequence

1. Fix the config (register models, set defaults)
2. Submit fresh commands via the API endpoint (e.g. rebuild)
3. Verify by checking the **output storage table**, not the command table
4. Ignore the lingering stale command records — they're database archaeology, not real work

### Verification

After submitting, confirm by querying the output layer:

```sql
SELECT count() FROM <output_table>
SELECT count(), source FROM <output_table> GROUP BY source
```

Compare total output records against expected input count. If counts match, the system is healthy regardless of stale command statuses.
