# Worked Example: Finding 6 Queued Discord Prompts

## Scenario

User works via CLI, but also sends messages via Discord while the agent is processing a long deployment (a kanban task picked up by the gateway). When the agent returns to the CLI session, the context has been compacted. The user says:

> "you were previously looking at 6 queued prompts from discord that i've sent in while waiting for that deployment to run"

## Step-by-Step Recovery

### 1. Browse Recent Sessions

```python
session_search()
```

Result shows sessions from multiple sources: `cli`, `tui`, `discord`.

### 2. Find the Discord Sessions

```python
session_search(query="discord", limit=5, sort="newest")
```

This returns all sessions where `source=discord`. In this case:
- `20260616_101353_8697d5e5` — Discord session about toad setup, launcher creation
- `20260616_125720_a9dd14` — Discord session about tools comparison, HTML report updates

### 3. Read the Discord Session

```python
session_search(session_id="20260616_101353_8697d5e5")
```

User messages appear with `[user]` prefix:
```
[user] add relevant info in this file to a skill for creating forks...
[user] do you have a skill for setting up and installing github repos?
[user] create the window launcher so i can click an icon to launch toad
[user] /q refactor and fix any code that's not working
[user] /q why does it still show you as typing?
```

### 4. Check for Sibling Sessions

The kanban hub deployment (t_56a7ebab) ran in a CLI session `20260616_151214_8af680`. The Discord session timestamps overlapped — these were the "queued prompts."

### 5. Present Findings

List each queued prompt with its context and current status (what was done, what's pending).

## Key Signals in This Pattern

- **"Queued prompts"** → user means messages on a different platform
- **"While waiting for that deployment"** → narrow by timestamp to when the deployment task was active
- **Discord messages with `/q` prefix** → quick/quiet mode on Discord Hermes bot
- **User messages tagged `[Username]`** → Discord session format

## Discord vs CLI Session Relationship

```
Time ──────────────────────────────────────────▶
                                                 
CLI Session:  [setup tasks] [deployment starts] [...waiting...] [done]
                                                    │
Discord:      [msg 1] [msg 2] [msg 3] [msg 4] [msg 5]
                                                    │
                                        These 5 messages are
                                        the "queued prompts"
```
