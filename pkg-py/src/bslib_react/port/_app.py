"""Start a Shiny app (Python or R) in the background and wait for it to answer.

Ported from ``tools/port/lib.R``'s ``port_start_app()`` / ``port_attach_app()``
/ ``port_stop_app()``. Used by the other port tools (``triage`` does not need
it, but ``deps_diff`` and ``peek`` both start one app per side to compare),
and by ``_catalog_render.py`` to serve page-kind catalog samples.

For a Python app, this is a thin wrapper around
``shiny.run.run_shiny_app()`` -- py-shiny's own subprocess runner already
does exactly what a hand-rolled "start in the background, hand me something
I can stop later" helper would do: pick a free port, launch
``python -m shiny run``, and block until it answers. Re-implementing that
would just be a worse copy of it.

For an R app there is no py-shiny equivalent, so this launches
``Rscript -e "shiny::runApp(...)"`` directly and polls over HTTP the same
way ``tools/port/lib.R`` does, letting a Python user diff an R parent
against a Python port with the same tool.
"""

from __future__ import annotations

import os
import re
import socket
import subprocess
import tempfile
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path

# A folder name this generic tells us nothing about the app; climb past it
# to find a name worth printing. Mirrors R's `port_app_name()`.
_GENERIC_DIR_NAMES = frozenset({"r", "R", "shiny", "app", "src", "inst"})

# Matches R's `port_app_log_errors()` grep pattern.
_LOG_ERROR_RE = re.compile(r"^(Warning|Error)|Error in|error in")


def _app_name(directory: Path) -> str:
    d = directory.resolve()
    while d.name in _GENERIC_DIR_NAMES and d.parent != d:
        d = d.parent
    return d.name or str(d)


def _free_port() -> int:
    """Bind to port 0, read back what the OS assigned, then release it.

    Same approach ``tools/port/lib.R`` takes via ``httpuv::randomPort()``:
    there's an inherent (tiny) race between releasing the socket here and
    the child process binding it, but it's the standard way to ask the OS
    for an unused port without a package dedicated to the purpose.
    """
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def _tail(path: Path | None, n: int) -> list[str]:
    if path is None or not path.is_file():
        return []
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    return lines[-n:]


def _wait_for_http(
    proc: subprocess.Popen, url: str, timeout: float, log: Path | None, name: str
) -> None:
    started = time.monotonic()
    while True:
        if proc.poll() is not None:
            tail = "\n".join(_tail(log, 40))
            raise RuntimeError(f"{name} exited before it listened.\n{tail}")
        try:
            with urllib.request.urlopen(url, timeout=2) as resp:
                if resp.status == 200:
                    return
        except (urllib.error.URLError, ConnectionError, TimeoutError, OSError):
            pass
        if time.monotonic() - started > timeout:
            proc.kill()
            tail = "\n".join(_tail(log, 40))
            raise RuntimeError(f"{name} did not answer within {timeout:.0f}s.\n{tail}")
        time.sleep(0.5)


@dataclass
class AppHandle:
    """A running app, started by :func:`start_app` or attached by :func:`attach_app`."""

    dir: Path | None
    name: str
    url: str
    proc: object | None
    log: Path | None

    def stop(self) -> None:
        """Terminate the app process, if this handle started one."""
        if self.proc is None:
            return
        close = getattr(self.proc, "close", None)
        if callable(close):
            close()
            return
        terminate = getattr(self.proc, "terminate", None)
        if callable(terminate):
            terminate()
            wait = getattr(self.proc, "wait", None)
            if callable(wait):
                try:
                    wait(timeout=5)
                except Exception:
                    kill = getattr(self.proc, "kill", None)
                    if callable(kill):
                        kill()

    def log_errors(self) -> list[str]:
        """Lines from the app's log that look like a warning or an error."""
        if self.log is not None:
            lines = _tail(self.log, 10_000)
        else:
            stderr = getattr(self.proc, "stderr", None)
            if stderr is None:
                return []
            lines = str(stderr).splitlines()
        return [line for line in lines if _LOG_ERROR_RE.search(line)]


def start_app(dir: str | Path, timeout: float = 120) -> AppHandle:
    """Start the Shiny app in ``dir`` in the background and wait until it answers.

    Looks for ``app.py`` first, then ``app.R``/``app.r``. Raises
    ``FileNotFoundError`` if ``dir`` doesn't exist or has neither, and
    ``RuntimeError`` if the app exits or fails to answer within ``timeout``
    seconds (with the app's log tail included in the message either way).
    """
    directory = Path(dir)
    if not directory.is_dir():
        raise FileNotFoundError(f"app directory not found: {directory}")

    name = _app_name(directory)
    py_app = directory / "app.py"
    if py_app.is_file():
        from shiny.run import run_shiny_app

        try:
            proc = run_shiny_app(
                str(py_app), port=0, cwd=str(directory), timeout_secs=timeout
            )
        except Exception as exc:
            raise RuntimeError(f"{name} did not become ready: {exc}") from exc
        return AppHandle(dir=directory, name=name, url=proc.url, proc=proc, log=None)

    r_app = next(
        (directory / n for n in ("app.R", "app.r") if (directory / n).is_file()), None
    )
    if r_app is not None:
        port = _free_port()
        log_path = Path(tempfile.mkstemp(prefix="bslib_react_port_", suffix=".log")[1])
        dir_posix = directory.resolve().as_posix()
        cmd = [
            "Rscript",
            "-e",
            f"shiny::runApp('{dir_posix}', port={port}, launch.browser=FALSE)",
        ]
        env = {**os.environ, "RENV_CONFIG_AUTOLOADER_ENABLED": "FALSE"}
        with log_path.open("w", encoding="utf-8") as logfile:
            proc = subprocess.Popen(
                cmd,
                cwd=str(directory),
                stdout=logfile,
                stderr=subprocess.STDOUT,
                env=env,
            )
        url = f"http://127.0.0.1:{port}/"
        try:
            _wait_for_http(proc, url, timeout, log_path, name)
        except Exception:
            proc.kill()
            raise
        return AppHandle(dir=directory, name=name, url=url, proc=proc, log=log_path)

    raise FileNotFoundError(f"no app.py or app.R/app.r found in {directory}")


def attach_app(url: str, name: str = "app") -> AppHandle:
    """Use an app that is already running instead of starting a new one."""
    if not url.endswith("/"):
        url = url + "/"
    try:
        with urllib.request.urlopen(url, timeout=5) as resp:
            ok = resp.status == 200
    except (urllib.error.URLError, ConnectionError, TimeoutError, OSError):
        ok = False
    if not ok:
        raise RuntimeError(f"nothing answers at {url}")
    return AppHandle(dir=None, name=name, url=url, proc=None, log=None)
