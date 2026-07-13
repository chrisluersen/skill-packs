"""Resolve HERMES_HOME for standalone skill scripts.

Skill scripts may run outside the Hermes process (e.g. system Python,
nix env, CI) where ``hermes_constants`` is not importable.  This module
provides the same ``get_hermes_home()`` and ``display_hermes_home()``
contracts as ``hermes_constants`` without requiring it on ``sys.path``.

When ``hermes_constants`` IS available it is used directly so that any
future enhancements (profile resolution, Docker detection, etc.) are
picked up automatically.  The fallback path replicates the core logic
from ``hermes_constants.py`` using only the stdlib.

All scripts under ``google-workspace/scripts/`` should import from here
instead of duplicating the ``HERMES_HOME = Path(os.getenv(...))`` pattern.
"""

from __future__ import annotations

import os
from pathlib import Path

try:
    from hermes_constants import display_hermes_home as display_hermes_home
    from hermes_constants import get_hermes_home as get_hermes_home
except (ModuleNotFoundError, ImportError):

    def _win32_home() -> Path:
        """Return home dir robust under git-bash/MSYS.

        ``Path.home()`` under git-bash returns MSYS-style
        ``/c/Users/...``, which can corrupt paths when joined
        with Windows drive prefixes.  ``USERPROFILE`` is always
        Win32-native even under git-bash.
        """
        return Path(os.environ.get("USERPROFILE", str(Path.home())))

    def get_hermes_home() -> Path:
        """Return the Hermes home directory (default: ~/.hermes).

        Mirrors ``hermes_constants.get_hermes_home()``."""
        val = os.environ.get("HERMES_HOME", "").strip()
        return Path(val) if val else _win32_home() / ".hermes"

    def display_hermes_home() -> str:
        """Return a user-friendly ``~/``-shortened display string.

        Mirrors ``hermes_constants.display_hermes_home()``."""
        home = get_hermes_home()
        try:
            return "~/" + str(home.relative_to(_win32_home()))
        except ValueError:
            return str(home)
