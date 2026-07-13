# Profile Description YAML Quoting Pitfall

When writing or updating per-profile `profile.yaml` files, descriptions containing a colon (`:`) followed by a space cause YAML parse errors.

## The Problem

```yaml
# BROKEN — YAML interprets "Best for:" as a mapping key
description: Klio-84 is the wiki specialist. Best for: wiki operations.
# Error: mapping values are not allowed here
```

The `write_file` linter catches this: `YAMLError: mapping values are not allowed here`.

## The Fix

Double-quote the entire value:

```yaml
description: "Klio-84 is the wiki specialist. Best for: wiki operations."
description_auto: true
```

## Verification

Check the lint field in the `write_file` response:
- `lint: {status: "ok"}` — good
- `lint: {status: "error", output: "YAMLError: ..."}` — wrap in double quotes

## Why

The `:` inside the YAML value is interpreted as a mapping separator when the value isn't quoted. Double quotes (`"..."`) disable YAML parsing of special characters inside the string. Single quotes (`'...'`) also work for simple text but don't handle embedded single quotes. Double quotes are preferred for description fields.