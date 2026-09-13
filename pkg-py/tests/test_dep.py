"""``bslib_react_dep()``: the vendored bundle, with and without a dev checkout."""

from pathlib import Path

from bslib_react import _dep


def test_version_is_the_bare_constant_without_a_dev_checkout(
    monkeypatch, tmp_path: Path
) -> None:
    monkeypatch.setattr(
        _dep, "_JS_PACKAGE_JSON", tmp_path / "does-not-exist" / "package.json"
    )
    dep = _dep.bslib_react_dep()
    # HTMLDependency parses `version=` into a packaging.version.Version.
    assert str(dep.version) == _dep._BSLIB_REACT_JS_VERSION


def test_version_gets_an_mtime_suffix_in_a_dev_checkout(
    monkeypatch, tmp_path: Path
) -> None:
    fake_package_json = tmp_path / "pkg-js" / "package.json"
    fake_package_json.parent.mkdir(parents=True)
    fake_package_json.write_text("{}", encoding="utf-8")

    fake_www = tmp_path / "www"
    fake_www.mkdir()
    bundle = fake_www / "bslib-react.js"
    bundle.write_text("/* bundle */", encoding="utf-8")
    known_mtime = 1_700_000_000
    import os

    os.utime(bundle, (known_mtime, known_mtime))

    monkeypatch.setattr(_dep, "_JS_PACKAGE_JSON", fake_package_json)
    monkeypatch.setattr(_dep, "_WWW_DIR", fake_www)

    version = _dep._bundle_version()
    assert version == f"{_dep._BSLIB_REACT_JS_VERSION}.{known_mtime}"


def test_script_tag_is_deferred_with_no_type_attribute() -> None:
    dep = _dep.bslib_react_dep()
    # HTMLDependency normalises a single script dict into a one-item list.
    script = dep.script[0]
    assert script.get("defer") == ""
    assert "type" not in script


def test_stylesheet_present_only_when_the_css_file_exists(
    monkeypatch, tmp_path: Path
) -> None:
    www_without_css = tmp_path / "www_no_css"
    www_without_css.mkdir()
    monkeypatch.setattr(_dep, "_WWW_DIR", www_without_css)
    dep_without_css = _dep.bslib_react_dep()
    # HTMLDependency normalises a missing stylesheet to an empty list.
    assert dep_without_css.stylesheet == []

    www_with_css = tmp_path / "www_with_css"
    www_with_css.mkdir()
    (www_with_css / "bslib-react.css").write_text("/* css */", encoding="utf-8")
    monkeypatch.setattr(_dep, "_WWW_DIR", www_with_css)
    dep_with_css = _dep.bslib_react_dep()
    assert dep_with_css.stylesheet[0]["href"] == "bslib-react.css"
