#!/usr/bin/env python3
"""Check that built Python artifacts carry the vendored bslibreact bundle.

The Python package is a thin server-side helper plus one vendored file:
src/bslibreact/www/bslibreact.js, copied from pkg-js's build by
`make update-dist`. Without it, bslibreact_dep() returns a dependency pointing
at nothing, so a wheel that loses the bundle installs and imports and then
serves a page with no components on it, for everyone, with no way to replace
the file: PyPI does not allow re-uploading a version.

    python tools/check_dist.py dist

Run it on a dist directory holding one sdist and one wheel. The release
workflow runs it between the build and the upload.
"""

from __future__ import annotations

import sys
import tarfile
import zipfile
from pathlib import Path

# The vendored bundle, and the size below which it is certainly a stub or an
# empty placeholder rather than a real build. A floor, not an exact size, so a
# component added to pkg-js does not break the release.
BUNDLE = "bslibreact/www/bslibreact.js"
MIN_BUNDLE_BYTES = 5_000

# Directories that exist in the repository but have no business in a release.
SDIST_JUNK = ("docs", "site", ".venv", "dist", "node_modules")


def fail(message: str) -> None:
    sys.exit(f"check_dist: {message}")


def check_wheel(path: Path) -> None:
    with zipfile.ZipFile(path) as zf:
        names = zf.namelist()
        if BUNDLE not in names:
            fail(f"{path.name}: missing {BUNDLE}")
        size = zf.getinfo(BUNDLE).file_size
        if size < MIN_BUNDLE_BYTES:
            fail(f"{path.name}: {BUNDLE} is {size} bytes, want {MIN_BUNDLE_BYTES}+")
    print(f"  {path.name}: carries {BUNDLE} ({size} bytes)")


def check_sdist(path: Path) -> None:
    with tarfile.open(path) as tf:
        names = tf.getnames()
        # The sdist root is a single <name>-<version>/ directory.
        wanted = [n for n in names if n.endswith(BUNDLE)]
        if not wanted:
            fail(f"{path.name}: missing {BUNDLE}")
        member = tf.getmember(wanted[0])
        if member.size < MIN_BUNDLE_BYTES:
            got = member.size
            fail(f"{path.name}: {BUNDLE} is {got} bytes, want {MIN_BUNDLE_BYTES}+")
        for junk in SDIST_JUNK:
            leaked = [n for n in names if f"/{junk}/" in n]
            if leaked:
                n = len(leaked)
                fail(f"{path.name}: contains {junk}/ ({n} entries), must not ship")
    print(f"  {path.name}: carries {BUNDLE} ({member.size} bytes), no junk directories")


def main(argv: list[str]) -> int:
    if len(argv) != 1:
        sys.exit(f"usage: {Path(__file__).name} DIST_DIR")

    dist = Path(argv[0])
    if not dist.is_dir():
        fail(f"{dist}: not a directory")

    wheels = sorted(dist.glob("*.whl"))
    sdists = sorted(dist.glob("*.tar.gz"))
    if not wheels:
        fail(f"{dist}: no wheel found")
    if not sdists:
        fail(f"{dist}: no sdist found")

    for wheel in wheels:
        check_wheel(wheel)
    for sdist in sdists:
        check_sdist(sdist)

    print(f"\nall {len(wheels) + len(sdists)} artifacts carry the vendored bundle")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
