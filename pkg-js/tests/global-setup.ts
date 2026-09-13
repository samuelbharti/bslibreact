import { spawnSync, type SpawnSyncReturns } from "node:child_process";
import { existsSync, mkdirSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import type { TestProject } from "vitest/node";

/**
 * Vitest `globalSetup`: runs exactly once, in Node (no jsdom, no React), before
 * any test file starts. This is where this package decides whether the R and
 * Python markup catalogs (see docs/markup-catalog.md at the repo root, and
 * this package's own tests/catalog.ts) are ready to read this session, and
 * hands that decision to every test file through vitest's `provide`/`inject`
 * mechanism (see the `declare module "vitest"` augmentation below).
 *
 * Why a globalSetup file, not a `beforeAll` inside catalog.ts: rendering a
 * catalog means spawning `Rscript` or `uv`, each of which can take real
 * seconds. Vitest runs test FILES in parallel worker processes; if every
 * file that imports catalog.ts independently checked freshness and
 * re-rendered on a cache miss, several workers could shell out to the same
 * renderer at once, stepping on the same output file. `globalSetup` runs
 * once, before any worker starts, so there is exactly one render pass per
 * language per `vitest run`, and every worker just reads the result.
 *
 * Why this must not throw by default: pkg-r and pkg-py are sibling
 * packages in this repo, built separately (see the root Makefile's r-* and
 * py-* targets). A `pkg-js` checkout can exist, and its own tests are
 * expected to run cleanly, before either sibling's renderer
 * (`tools/markup/render-r.R`, `tools/markup/render_py.py`) has been
 * written at all. Every state below short of "ready" is therefore treated
 * as "skip the tests that need this language, loudly, but do not fail the
 * suite" - UNLESS BSLIB_REACT_REQUIRE_CATALOG=1 is set, which is what CI
 * sets once both renderers are expected to actually exist, so a real
 * regression there cannot hide behind a quiet skip.
 */

export type CatalogState = "ready" | "missing-tool" | "renderer-missing" | "renderer-error";

export type CatalogLangStatus = {
  state: CatalogState;
  /** Where the rendered catalog is expected to live (.cache/markup/<lang>.json),
   *  whether or not it actually exists. catalog.ts reads the file from here
   *  once state is "ready". */
  path: string;
  /** Human-readable explanation for a non-"ready" state: what this setup
   *  tried, and what happened. Absent when state is "ready". */
  detail?: string;
};

export type CatalogStatusByLang = { r: CatalogLangStatus; py: CatalogLangStatus };

// Augments vitest's own (otherwise empty) ProvidedContext interface so that
// `project.provide("bslibReactCatalog", ...)` below, and every test file's
// own `inject("bslibReactCatalog")` (see tests/catalog.ts's catalogStatus()),
// type-check against the real shape instead of `any`.
declare module "vitest" {
  export interface ProvidedContext {
    bslibReactCatalog: CatalogStatusByLang;
  }
}

type Lang = "r" | "py";

const TESTS_DIR = dirname(fileURLToPath(import.meta.url));
const PKG_JS_DIR = dirname(TESTS_DIR);
const REPO_ROOT = dirname(PKG_JS_DIR);
const CACHE_DIR = join(REPO_ROOT, ".cache", "markup");

// Tool-path overrides: a machine with R or uv installed somewhere not on
// the default PATH (a version manager, a CI image with a non-standard
// layout) can point straight at the binary without this file needing to
// know anything about how it got there.
const RSCRIPT = process.env.BSLIB_REACT_RSCRIPT || "Rscript";
const UV = process.env.BSLIB_REACT_UV || "uv";
const RENDER_R_SCRIPT = join(REPO_ROOT, "tools", "markup", "render-r.R");
const RENDER_PY_SCRIPT = join(REPO_ROOT, "tools", "markup", "render_py.py");

function run(command: string, args: string[]): SpawnSyncReturns<string> {
  // shell: true so Windows resolves Rscript.exe / uv.exe (and any .cmd
  // shim a version manager installs) off PATH the same way a person typing
  // the command at a prompt would. Without it, spawnSync on Windows often
  // reports ENOENT for a tool that is genuinely installed, because it will
  // not consult PATHEXT itself the way cmd.exe does.
  return spawnSync(command, args, { cwd: REPO_ROOT, shell: true, encoding: "utf8" });
}

function toolOnPath(command: string): { ok: boolean; detail?: string } {
  const result = run(command, ["--version"]);
  if (result.error) return { ok: false, detail: result.error.message };
  if (result.status !== 0) {
    return { ok: false, detail: `"${command} --version" exited ${String(result.status)}` };
  }
  return { ok: true };
}

function describeFailure(commandLabel: string, result: SpawnSyncReturns<string>): string {
  if (result.error) return `${commandLabel} failed to start: ${result.error.message}`;
  const firstStderrLine = (result.stderr ?? "").trim().split("\n")[0];
  return `${commandLabel} exited ${String(result.status)}${firstStderrLine ? `: ${firstStderrLine}` : ""}`;
}

function readCachedKey(cachePath: string): string | undefined {
  if (!existsSync(cachePath)) return undefined;
  try {
    const parsed = JSON.parse(readFileSync(cachePath, "utf8")) as { key?: unknown };
    return typeof parsed.key === "string" ? parsed.key : undefined;
  } catch {
    // A cache file that exists but will not parse (truncated by a killed
    // render, hand-edited, from a schema this reader predates) is exactly
    // as unusable as a missing one: treat it as "no cached key", which
    // forces a fresh render below rather than crashing this setup.
    return undefined;
  }
}

/**
 * Compare `key` (what `--key` just reported) against what is already
 * cached at `cachePath`, and re-render only when they differ. Shared by
 * both languages; only the actual render command differs between them.
 */
function ensureFresh(
  cachePath: string,
  key: string,
  renderCommandLabel: string,
  render: () => SpawnSyncReturns<string>,
): CatalogLangStatus {
  if (readCachedKey(cachePath) === key) {
    return { state: "ready", path: cachePath };
  }
  mkdirSync(dirname(cachePath), { recursive: true });
  const result = render();
  if (result.error || result.status !== 0) {
    return {
      state: "renderer-error",
      path: cachePath,
      detail: describeFailure(renderCommandLabel, result),
    };
  }
  const renderedKey = readCachedKey(cachePath);
  if (renderedKey !== key) {
    return {
      state: "renderer-error",
      path: cachePath,
      detail:
        `rendered ${cachePath}, but its "key" (${renderedKey ? `"${renderedKey}"` : "missing"}) does ` +
        `not match what --key reported ("${key}") - the render may have used different input than ` +
        "the one --key measured, or the renderer's --out did not write the file --key describes",
    };
  }
  return { state: "ready", path: cachePath };
}

function resolveR(): CatalogLangStatus {
  const cachePath = join(CACHE_DIR, "r.json");

  const tool = toolOnPath(RSCRIPT);
  if (!tool.ok) {
    return {
      state: "missing-tool",
      path: cachePath,
      detail: `"${RSCRIPT}" is not on PATH (${tool.detail ?? "unknown error"}). Install R, or point BSLIB_REACT_RSCRIPT at Rscript.`,
    };
  }

  if (!existsSync(RENDER_R_SCRIPT)) {
    return {
      state: "renderer-missing",
      path: cachePath,
      detail: `tools/markup/render-r.R does not exist yet (looked at ${RENDER_R_SCRIPT}). It ships from pkg-r; nothing to render against until that package lands.`,
    };
  }

  const keyResult = run(RSCRIPT, [RENDER_R_SCRIPT, "--key"]);
  if (keyResult.error || keyResult.status !== 0) {
    return {
      state: "renderer-missing",
      path: cachePath,
      detail: describeFailure(`${RSCRIPT} tools/markup/render-r.R --key`, keyResult),
    };
  }

  const key = keyResult.stdout.trim();
  return ensureFresh(cachePath, key, `${RSCRIPT} tools/markup/render-r.R --out`, () =>
    run(RSCRIPT, [RENDER_R_SCRIPT, "--out", cachePath]),
  );
}

function resolvePy(): CatalogLangStatus {
  const cachePath = join(CACHE_DIR, "py.json");

  const tool = toolOnPath(UV);
  if (!tool.ok) {
    return {
      state: "missing-tool",
      path: cachePath,
      detail: `"${UV}" is not on PATH (${tool.detail ?? "unknown error"}). Install uv, or point BSLIB_REACT_UV at it.`,
    };
  }

  if (!existsSync(RENDER_PY_SCRIPT)) {
    return {
      state: "renderer-missing",
      path: cachePath,
      detail: `tools/markup/render_py.py does not exist yet (looked at ${RENDER_PY_SCRIPT}). It ships from pkg-py, nothing to render against until that package lands.`,
    };
  }

  const keyResult = run(UV, ["run", "python", RENDER_PY_SCRIPT, "--key"]);
  if (keyResult.error || keyResult.status !== 0) {
    return {
      state: "renderer-missing",
      path: cachePath,
      detail: describeFailure(`${UV} run python tools/markup/render_py.py --key`, keyResult),
    };
  }

  const key = keyResult.stdout.trim();
  return ensureFresh(cachePath, key, `${UV} run python tools/markup/render_py.py --out`, () =>
    run(UV, ["run", "python", RENDER_PY_SCRIPT, "--out", cachePath]),
  );
}

const STATE_EXPLAIN: Record<Exclude<CatalogState, "ready">, string> = {
  "missing-tool": "the interpreter itself is not installed, or not on PATH",
  "renderer-missing": "the catalog renderer is not available yet",
  "renderer-error": "the renderer ran, but rendering the catalog failed",
};

function warnBanner(lang: Lang, status: CatalogLangStatus): void {
  const pkg = lang === "r" ? "pkg-r" : "pkg-py";
  const state = status.state;
  if (state === "ready") return;
  console.warn(
    [
      "",
      `[bslib-react] markup catalog for "${lang}" is not ready: ${state}.`,
      `  ${STATE_EXPLAIN[state]}.`,
      status.detail ? `  ${status.detail}` : undefined,
      `  Every test that reads the "${lang}" catalog (describeCatalog("${lang}", ...),`,
      "  and tests/parity.test.ts once both languages are involved) will SKIP, not",
      `  fail, until ${pkg} and its renderer are in place and a render has produced`,
      `  ${status.path}.`,
      "  Set BSLIB_REACT_REQUIRE_CATALOG=1 to turn this into a hard failure instead -",
      "  CI does this, so a real regression cannot hide behind a quiet skip.",
      "",
    ]
      .filter((line): line is string => line !== undefined)
      .join("\n"),
  );
}

export default function setup(project: TestProject): void {
  const statuses: CatalogStatusByLang = { r: resolveR(), py: resolvePy() };

  const hardFailures: string[] = [];
  for (const lang of ["r", "py"] as const) {
    const status = statuses[lang];
    if (status.state === "ready") continue;
    warnBanner(lang, status);
    if (process.env.BSLIB_REACT_REQUIRE_CATALOG === "1") {
      hardFailures.push(`${lang}: ${status.state}${status.detail ? ` - ${status.detail}` : ""}`);
    }
  }

  if (hardFailures.length > 0) {
    throw new Error(
      "BSLIB_REACT_REQUIRE_CATALOG=1 is set, so a markup catalog that is not ready is " +
        `a hard failure, not a skip:\n  ${hardFailures.join("\n  ")}`,
    );
  }

  project.provide("bslibReactCatalog", statuses);
}
