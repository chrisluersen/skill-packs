---
name: signal-cli
description: Install, configure, and register Signal CLI on Windows for local Signal messaging access.
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [windows]
metadata:
  hermes:
    tags: [signal, messaging, sms, cli, windows]
    related_skills: [self-hosted-services]
created_from_user_sessions: true
---

# Signal CLI on Windows

Use when setting up `signal-cli` locally for the first time, registering a phone
number, or reconfiguring an existing install. This class of task turns into a
repeatable recipe: ensure Java 17, install the CLI, verify the binary, then
register.

## Prerequisites

- Windows 10+
- Admin rights for `winget`/Java install
- A phone number that can receive SMS or a Signal app instance for linking

## Install Java 17

signal-cli requires Java 17+.

```powershell
winget install --id Oracle.JDK.17 --silent --accept-package-agreements --accept-source-agreements
# or
winget install --id EclipseAdoptium.Temurin.17.JDK --silent
```

Verify:
```powershell
java -version
```

## Install signal-cli

The easiest route on Windows is the official prebuilt binary from the signal-cli
GitHub Releases page. Do not build from source unless the user explicitly wants
it; the build path adds extra Java/Gradle dependencies and is more likely to
fail on a fresh Windows box.

Set install dir (example):
```powershell
$SignalCliDir = "$env:LOCALAPPDATA\signal-cli"
New-Item -Path $SignalCliDir -ItemType Directory -Force | Out-Null
# download the latest .zip from https://github.com/AsamK/signal-cli/releases
# extract signal-cli-*-Windows.tar.gz / .zip to $SignalCliDir
```

Add to PATH if missing:
```powershell
$current = [Environment]::GetEnvironmentVariable("Path", "User")
if ($current -notlike "*$SignalCliDir*") {
  [Environment]::SetEnvironmentVariable("Path", "$current;$SignalCliDir", "User")
}
```

Verify:
```powershell
signal-cli --version
```

## Register / Link

If signal-cli is not yet linked to a number:
```powershell
signal-cli link -n "DeviceName"
```

This prints a URI or starts a linking interaction. If linking by SMS:
```powershell
signal-cli link -n "DeviceName" --uri <linking-uri>
```

Confirm registration:
```powershell
signal-cli listAccounts
```

## Common Pitfalls

- If `signal-cli` reports a missing JRE, double-check `java -version` and ensure
  the PATH points to a JDK 17+, not an older JRE.
- If `winget` installs a JDK but `java -version` still shows something else, the
  user likely has an older JRE earlier in PATH. Fix PATH order before retrying.
- Registration requires a usable Signal network path: phone/SMS or an existing
  linked device.
- On Windows, avoid MSYS/Git Bash when running `signal-cli` if you hit
  path-translation or quoting issues. Use `cmd.exe /c` or PowerShell.