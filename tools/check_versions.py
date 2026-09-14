#!/usr/bin/env python3
"""Check that every declared version agrees.

The R, Python, and JavaScript packages ship as one project and share a single
version, so the number is written in several places. Nothing keeps them in step
on its own, and the one that drifts is usually noticed only after a release is
out, when it cannot be taken back. This script is the check.

Run it with no argument to compare the files to each other:

    python tools/check_versions.py

Pass a release tag to also require the files to match what is being released.
A leading "v" is optional, so both forms work:

    python tools/check_versions.py v0.1.0

The release workflows run it with the tag before building anything, which is the
point where a mismatch is still free to fix.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Each entry is a file and the pattern whose first group is its version. The
# patterns are anchored to the start of a line so a version named in prose or in
# a dependency pin is never picked up by mistake.
SOURCES = (
    ("pyproject.toml", r'^version\s*=\s*"([^"]+)"'),
    # uv.lock records the project's own version, and it is one that drifts
    # quietly: bumping pyproject.toml without re-running `uv lock` leaves it
    # behind. Anchored to this project's own stanza, not a dependency's.
    ("uv.lock", r'^name = "bslib-react"\nversion = "([^"]+)"'),
    ("pkg-r/DESCRIPTION", r"^Version:\s*(\S+)"),
    ("pkg-r/NEWS.md", r"^#\s+bslibreact\s+(\d\S*)"),
    # Both changelogs may carry an unreleased section between releases, so these
    # match the first heading that starts with a digit and skip anything else.
    ("pkg-js/CHANGELOG.md", r"^##\s+(\d\S*)"),
    ("pkg-py/CHANGELOG.md", r"^##\s+(\d\S*)"),
    # The key is indented in package.json, so the anchor allows leading
    # whitespace rather than binding to the start of the line.
    ("pkg-js/package.json", r'^\s*"version":\s*"([^"]+)"'),
    # The version each package reports for its vendored bslib-react.js bundle.
    # These are separate constants from the package version and have to be
    # bumped by hand, so they drift the same way a lock file does.
    ("pkg-r/R/dep.R", r'^\.bslib_react_js_version <- "([^"]+)"'),
    ("pkg-py/src/bslib_react/_dep.py", r'^_BSLIB_REACT_JS_VERSION = "([^"]+)"'),
    ("pkg-py/src/bslib_react/_version.py", r'^\s*__version__ = "([^"]+)"'),
    ("pkg-py/tests/test_version.py", r'^_EXPECTED_VERSION = "([^"]+)"'),
)

# package-lock.json is JSON rather than a line match: pkg-js is a workspace, so
# the version that matters is the one recorded for that workspace, not the root
# object's. It drifts exactly as uv.lock does, when package.json is bumped
# without `npm install`.
LOCKFILE = "package-lock.json"
LOCK_WORKSPACE = "pkg-js"


def read_version(relative: str, pattern: str) -> str:
    """Return the version `pattern` finds in `relative`, or exit explaining why not."""
    path = ROOT / relative
    if not path.is_file():
        sys.exit(f"{relative}: not found")
    match = re.search(pattern, path.read_text(encoding="utf-8"), re.MULTILINE)
    if match is None:
        sys.exit(f"{relative}: no version matching {pattern!r}")
    return match.group(1).strip().strip('"')


def read_lock_version() -> str:
    """Return the version package-lock.json records for the pkg-js workspace."""
    path = ROOT / LOCKFILE
    if not path.is_file():
        sys.exit(f"{LOCKFILE}: not found")
    data = json.loads(path.read_text(encoding="utf-8"))
    entry = data.get("packages", {}).get(LOCK_WORKSPACE)
    if not entry or "version" not in entry:
        sys.exit(f"{LOCKFILE}: no version recorded for {LOCK_WORKSPACE!r}")
    return str(entry["version"])


def main(argv: list[str]) -> int:
    if len(argv) > 1:
        sys.exit(f"usage: {Path(__file__).name} [TAG]")

    found = {name: read_version(name, pattern) for name, pattern in SOURCES}
    found[f"{LOCKFILE} ({LOCK_WORKSPACE})"] = read_lock_version()

    expected = None
    if argv:
        expected = argv[0][1:] if argv[0].startswith("v") else argv[0]

    width = max(len(name) for name in found)
    for name, version in found.items():
        print(f"  {name:<{width}}  {version}")

    distinct = set(found.values())
    if len(distinct) > 1:
        print()
        sys.exit(f"versions disagree: {', '.join(sorted(distinct))}")

    version = distinct.pop()
    if expected is not None and version != expected:
        print()
        sys.exit(f"tag is {expected} but the files say {version}")

    print()
    print(f"all versions agree: {version}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
