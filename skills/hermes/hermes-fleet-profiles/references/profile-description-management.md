## Profile Description Management

Each Hermes fleet profile has a `profile.yaml` storing a short "what is this agent good at?" description. These appear in the WebUI profile picker and gateway profile list.

### File locations

| Profile | Path |
|---------|------|
| Default (Stella) | `~/AppData/Local/hermes\AppData\Local\hermes\profile.yaml` |
| Fleet specialists | `~/AppData/Local/hermes\AppData\Local\hermes\profiles/<name>/profile.yaml` |

The default profile lives at the root (`~/.hermes/profile.yaml`), NOT under `profiles/default/`. There is no `profiles/default/` directory.

### YAML format

```yaml
description: "Single quoted string describing what this profile is good at."
description_auto: true
```

### Critical: YAML quoting pitfall

**Colons (`:`)** inside description values are parsed as YAML mapping separators. This causes a `YAMLError: mapping values are not allowed here` if the description contains phrases like "Best for:" or "Uses:" without the whole value being quoted.

❌ **Wrong** (colons trigger parse errors):
```yaml
description: Best for: research tasks — uses web search tools.
```

✅ **Right** (entire value double-quoted):
```yaml
description: "Best for: research tasks — uses web search tools."
```

The double quotes protect internal colons. Always wrap descriptions in double quotes as a defensive practice, even when you don't think there's a colon — titles, lists, and em dash constructions may introduce one unexpectedly.

### The `description_auto: true` convention

This field signals that the description was generated or updated by the agent rather than hand-authored by the user. It prevents future curator passes from overwriting a manual edit with a re-generated auto-description.

- Set to `true` when you create or update a description as an agent
- Set to `false` (or omit) when the user hand-writes one
- Most fleet profiles should have `description_auto: true` since they were created from template
- User-authored descriptions should set `description_auto: false` so the curator won't touch them

### What makes a good description

Each description should answer: "What should I send this agent for?" in one sentence.

Template:
```yaml
description: "<Name> is the fleet's <role> specialist. <1-2 sentences on specific capabilities — tools, models, workflow patterns.> Best for: <concrete use cases>."
```

Example:
```yaml
description: "Metis-9 is the fleet's coding & software engineering specialist. Full-stack development, feature implementation, PR lifecycle (branching, CI, merge), and debugging complex codebases. Uses deepseek-v4-flash with 50-turn depth for sustained coding sessions. Your primary engineering arm."
```