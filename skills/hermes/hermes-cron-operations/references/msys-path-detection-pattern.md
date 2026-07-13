# MSYS Path Detection Pattern (Windows Cron Scripts)

When cron scripts run on Windows with MSYS/git-bash, environment variables like
`HERMES_HOME` arrive in POSIX format (`~/AppData/Local/hermes/...`) instead of Windows
format (`~/AppData/Local/hermes\...`). Passing these paths to `Path()` or `sqlite3.connect()`
produces garbage paths like `C:\c\Users\...`.

## The Fix

Replace any fragile path resolution like:

```python
HERMES_HOME = Path(os.environ.get('HERMES_HOME', str(Path.home() / 'AppData/Local/hermes')))
```

With the detection pattern:

```python
import os, re
from pathlib import Path

def _resolve_home_path(env_var=None, fallback=None):
    """Resolve a home-equivalent path with MSYS detection.

    Args:
        env_var: Environment variable name to check first (e.g. 'HERMES_HOME').
        fallback: Path to use if env_var is unset.

    Returns a Path guaranteed to have native Windows format.
    """
    raw = os.environ.get(env_var, '') if env_var else ''
    if not raw:
        return fallback if fallback else Path.home()

    _m = re.match(r'^/([a-zA-Z])/(.+)', raw)
    if _m:
        _drive = f"{_m.group(1).upper()}:"
        _rest = _m.group(2).replace('/', os.sep)
        return Path(_drive + os.sep + _rest)
    return Path(raw)

# Usage:
_HERMES_FALLBACK = Path(os.environ.get('LOCALAPPDATA', '')) / 'hermes' \
    if os.environ.get('LOCALAPPDATA') \
    else Path.home() / 'AppData/Local/hermes'

HERMES_HOME = _resolve_home_path('HERMES_HOME', _HERMES_FALLBACK)
```

## For User Home Paths

`USERPROFILE` is always Win32-native (Windows system env var, never
MSYS-translated). Prefer it over `Path.home()`:

```python
_HOME = Path(os.environ.get('USERPROFILE', str(Path.home())))
ONEDRIVE = _HOME / "OneDrive/hermes-backup"
```

But `os.path.expanduser("~/Downloads")` IS MSYS-mangled — don't use it.
Replace with:

```python
_HOME = os.environ.get('USERPROFILE', '') or os.path.expanduser('~')
if _HOME.startswith('/'):
    _m_h = re.match(r'^/([a-zA-Z])/(.+)', _HOME)
    if _m_h:
        _drive = f"{_m_h.group(1).upper()}:"
        _rest = _m_h.group(2).replace('/', os.sep)
        _HOME = _drive + os.sep + _rest

downloads = os.path.join(_HOME, "Downloads")  # instead of expanduser("~/Downloads")
```

## Critical: Python <3.12 f-string Backslash Trap

**Never put `\\` inside an f-string** — Python <3.12 raises `SyntaxError: f-string expression part cannot include a backslash`:

```python
# ❌ BROKEN on Python <3.12
_drive = f"{_m.group(1).upper()}:\\"    # SyntaxError!
_rest = _m.group(2).replace('/', '\\')  # Also an f-string

# ✅ WORKS everywhere — use os.sep + string concat outside f-strings
_drive = f"{_m.group(1).upper()}:"
_rest = _m.group(2).replace('/', os.sep)
result = Path(_drive + os.sep + _rest)
```

The rule: **build the backslash outside the f-string** using `os.sep` or a temp variable, then concatenate.

## Inline Pattern (no function, no function call overhead)

For simpler scripts where a function is overkill, this inline pattern works
identically and is self-contained:

```python
import os, re

_HOME = os.environ.get('USERPROFILE', '') or os.path.expanduser('~')
if _HOME.startswith('/'):
    _m_h = re.match(r'^/([a-zA-Z])/(.+)', _HOME)
    if _m_h:
        _drive = f"{_m_h.group(1).upper()}:"
        _rest = _m_h.group(2).replace('/', os.sep)
        _HOME = _drive + os.sep + _rest
_HOME_RAW = _HOME
```

Then use `_HOME_RAW` with `os.path.join()` instead of `os.path.expanduser()`.

## Pitfalls

| Pitfall | Detail |
|---------|--------|
| **`Path("C:")` is RELATIVE** | `Path("C:") / "Users"` gives `C:Users` (relative to current dir on drive C), **not** `C:\Users`. Always use `Path("C:\\")` (with escaped backslash for drive root). |
| **Don't import `re` at top level if rarely used** | Import `re` inside the condition block to avoid an unused import when the env var is not set. Alternatively, import unconditionally — the import cost is negligible. |
| **`os.sep` vs hardcoded `\\`** | `os.sep` is `'\\'` on Windows and `'/'` on Linux. Using it makes the pattern cross-platform. For scripts that only run on Windows, `'\\'` works too — but `os.sep` costs nothing and prevents future bugs. |
| **`expanduser("~/Downloads")` is always MSYS-mangled** | Never use this in cron scripts. Always use the MSYS detection pattern or `USERPROFILE`. |

## Verification

```python
# Test with MSYS-mangled HERMES_HOME
import os, re
from pathlib import Path

os.environ['HERMES_HOME'] = '~/AppData/Local/hermes/AppData/Local/hermes'
# ... apply the pattern ...
assert str(HERMES_HOME) == '~/AppData/Local/hermes\\AppData\\Local\\hermes'

# Test with native Windows path
os.environ['HERMES_HOME'] = '~/AppData/Local/hermes\\AppData\\Local\\hermes'
# ... apply the pattern ...
assert str(HERMES_HOME) == '~/AppData/Local/hermes\\AppData\\Local\\hermes'

# Test with no env var (LOCALAPPDATA fallback)
del os.environ['HERMES_HOME']
# ... apply the pattern ...
assert str(HERMES_HOME) == '~/AppData/Local/hermes\\AppData\\Local\\hermes'

# Test expanduser replacement
os.environ.pop('HERMES_HOME', None)
_HOME = os.environ.get('USERPROFILE', '')
# MSYS simulation: ~/AppData/Local/hermes
if not _HOME:
    _HOME = '~/AppData/Local/hermes'
if _HOME.startswith('/'):
    _m_h = re.match(r'^/([a-zA-Z])/(.+)', _HOME)
    if _m_h:
        _drive = f"{_m_h.group(1).upper()}:"
        _rest = _m_h.group(2).replace('/', os.sep)
        _HOME = _drive + os.sep + _rest
assert _HOME == '~/AppData/Local/hermes'
assert os.path.join(_HOME, 'Downloads') == '~/AppData/Local/hermes\\Downloads'
```
