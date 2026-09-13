"""``create_app()``: scaffold a new app from the bundled template."""

from __future__ import annotations

from pathlib import Path

import pytest
from bslib_react import create_app

_EXPECTED_FILES = {
    "app.py",
    "package.json",
    "tsconfig.json",
    "vite.config.ts",
    "src/App.tsx",
    "src/ui.tsx",
    "tests/playwright/test_app.py",
}


def test_scaffolded_file_list_matches_the_template(tmp_path: Path) -> None:
    dest = create_app(tmp_path / "myapp", name="myapp", title="My App")
    files = {
        str(p.relative_to(dest)).replace("\\", "/")
        for p in dest.rglob("*")
        if p.is_file()
    }
    assert files == _EXPECTED_FILES


def test_no_placeholder_survives_substitution(tmp_path: Path) -> None:
    dest = create_app(tmp_path / "myapp", name="myapp", title="My App")
    for path in dest.rglob("*"):
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        assert "APP_NAME" not in text, path
        assert "APP_TITLE" not in text, path
        assert "BSLIB_REACT_VERSION" not in text, path


def test_app_py_is_syntactically_valid(tmp_path: Path) -> None:
    dest = create_app(tmp_path / "myapp", name="myapp", title="My App")
    source = (dest / "app.py").read_text(encoding="utf-8")
    compile(source, "app.py", "exec")  # raises SyntaxError if this ever regresses


def test_name_and_title_default_from_the_directory_name(tmp_path: Path) -> None:
    dest = create_app(tmp_path / "some-app")
    text = (dest / "app.py").read_text(encoding="utf-8")
    assert 'title="some-app"' in text
    package_json = (dest / "package.json").read_text(encoding="utf-8")
    assert '"name": "some-app"' in package_json


def test_refuses_to_scaffold_into_a_nonempty_directory(tmp_path: Path) -> None:
    dest = tmp_path / "occupied"
    dest.mkdir()
    (dest / "existing.txt").write_text("hi", encoding="utf-8")
    with pytest.raises(FileExistsError):
        create_app(dest)


def test_brand_writes_a_starter_brand_yml(tmp_path: Path) -> None:
    dest = create_app(tmp_path / "branded", brand=True)
    assert (dest / "_brand.yml").is_file()
