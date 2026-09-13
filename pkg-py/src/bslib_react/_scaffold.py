"""``create_app()``: scaffold a new bslib-react app from the bundled template.

Copies ``templates/app-py/`` (the server, the client entry points, and their
build config) to a new directory, substituting the app's name and title, and
the installed package's own version, into the three placeholders the
template files use (``APP_NAME``, ``APP_TITLE``, ``BSLIB_REACT_VERSION``).
"""

from __future__ import annotations

from pathlib import Path

from ._version import __version__

_TEMPLATE_DIR = Path(__file__).parent / "templates" / "app-py"

_BRAND_TEMPLATE = """\
meta:
  name: {title}

color:
  palette:
    primary: "#446e9b"
  primary: primary

typography:
  base: system-ui
"""


def _substitute(text: str, name: str, title: str) -> str:
    return (
        text.replace("APP_TITLE", title)
        .replace("APP_NAME", name)
        .replace("BSLIB_REACT_VERSION", __version__)
    )


def create_app(
    path: str | Path,
    *,
    name: str | None = None,
    title: str | None = None,
    brand: bool = False,
) -> Path:
    """Scaffold a new bslib-react app at ``path``.

    Args:
        path: Where to create the app. Created if it doesn't exist; must be
            empty (or absent) if it does, so this never overwrites an
            existing project by accident.
        name: The app's name, used as the npm package name in
            ``package.json``. Defaults to ``path``'s directory name.
        title: The page title used in ``app.py``. Defaults to ``name``.
        brand: Also write a starter ``_brand.yml``, so ``app.py``'s
            ``ui.Theme.from_brand()`` branch has something to load.

    Returns:
        The path the app was scaffolded into (same as ``path``, resolved).

    Raises:
        FileExistsError: If ``path`` exists and already has files in it.
    """
    dest = Path(path)
    if dest.exists() and any(dest.iterdir()):
        raise FileExistsError(f"create_app(): {dest} already exists and is not empty")
    dest.mkdir(parents=True, exist_ok=True)

    app_name = name if name is not None else dest.resolve().name
    app_title = title if title is not None else app_name

    for src in sorted(_TEMPLATE_DIR.rglob("*")):
        if src.is_dir():
            continue
        rel = src.relative_to(_TEMPLATE_DIR)
        target = dest / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        text = src.read_text(encoding="utf-8")
        target.write_text(_substitute(text, app_name, app_title), encoding="utf-8")

    if brand:
        (dest / "_brand.yml").write_text(
            _BRAND_TEMPLATE.format(title=app_title), encoding="utf-8"
        )

    return dest
