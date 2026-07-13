# Windows Native Binary MCP Wrapper Pattern

This file documents the proven pattern for wrapping a Windows native binary as a stdio MCP server when the binary itself doesn't handle stdio correctly from git-bash/MSYS2.

## The Problem

Windows native PE32+ executables (`something.exe`) compiled with MSVC or Go or Rust may not properly handle MCP's JSON-RPC over stdin/stdout when spawned from git-bash/MSYS2. The binary starts but never produces JSON-RPC responses, causing:

```
MCP: 1 server(s) failed to connect - server-name
```

The executable works fine interactively but fails as an MCP subprocess because the pipe bridge between MSYS and native Windows stdio isn't fully transparent for the MCP protocol.

## The Pattern: Python FastMCP Wrapper

Write a Python script that:
1. Handles the MCP stdio protocol natively (Python does this correctly on Windows)
2. Calls the native binary via `subprocess.run()` for each tool invocation

```python
#!/usr/bin/env python3
"""MCP wrapper for native-tool.exe."""
import subprocess, os, shutil, json
from pathlib import Path
from mcp.server.fastmcp import FastMCP

# Resolve the native binary
TOOL_CMD = shutil.which("native-tool") or str(Path.home() / ".bun/bin/native-tool.exe")

# Build the correct env (shell env vars may not pass through)
ENV = os.environ.copy()
ENV["PATH"] = f"{Path.home() / '.bun/bin'}{os.pathsep}{ENV.get('PATH', '')}"

mcp = FastMCP("wrapper-name", instructions="...")

@mcp.tool()
def my_tool(query: str) -> str:
    result = subprocess.run(
        [TOOL_CMD, query],
        capture_output=True, text=True, timeout=30, env=ENV
    )
    if result.returncode != 0:
        return f"Error: {result.stderr}"
    return result.stdout

# ...more tools...

mcp.run(transport="stdio")
```

## Config Wiring

Wire the **Python script** (not the native EXE) into Hermes config.yaml:

```yaml
mcp_servers:
  my-tool:
    command: "python"
    args: ["C:/path/to/wrapper.py"]
```

Pass any required API keys via the `env:` config key (shell env vars are filtered):

```yaml
mcp_servers:
  my-tool:
    command: "python"
    args: ["wrapper.py"]
    env:
      ZEROENTROPY_API_KEY: "ze_..."
```

## Concrete Example: gbrain

The `gbrain-mcp-server.py` at `scripts/gbrain-mcp-server.py` is a working implementation of this pattern. It wraps 7+ gbrain tools via subprocess calls to `gbrain.exe`. See that file for a complete reference.
