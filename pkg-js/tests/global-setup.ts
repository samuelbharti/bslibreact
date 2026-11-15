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
 * Why this does not throw by default: a machine with no R or no uv should
 * still run pkg-js's own tests. Every state short of "ready" skips the
 * tests that need that language, loudly, unless
 * BSLIBREACT_REQUIRE_CATALOG=1 is set, which CI sets so a broken renderer
 * fails there and cannot hide behind a quiet skip.
 */

export type CatalogState = "ready" | "missing-tool" | "renderer-error";

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
// `project.provide("bslibreactCatalog", ...)` below, and every test file's
// own `inject("bslibreactCatalog")` (see tests/catalog.ts's catalogStatus()),
// type-check against the real shape instead of `any`.
declare module "vitest" {
  export interface ProvidedContext {
    bslibreactCatalog: CatalogStatusByLang;
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
const RSCRIPT = process.env.BSLIBREACT_RSCRIPT || "Rscript";
const UV = process.env.BSLIBREACT_UV || "uv";
const RENDER_R_SCRIPT = join(REPO_ROOT, "tools", "markup", "render-r.R");
const RENDER_PY_SCRIPT = join(REPO_ROOT, "tools", "markup", "render_py.py");

function run(command: string, args: string[]): SpawnSyncReturns<string> {
  const options = { cwd: REPO_ROOT, encoding: "utf8" } as const;
  const direct = spawnSync(command, args, options);
  const notFound = (direct.error as NodeJS.ErrnoException | undefined)?.code === "ENOENT";
  if (process.platform !== "win32" || !notFound) return direct;
  // Windows finds only .exe and .com files on its own. A version manager's
  // .bat or .cmd shim (rig installs Rscript.bat) needs cmd.exe: one quoted
  // command string, so paths with spaces stay whole and Node does not warn
  // about an args array with shell: true (DEP0190).
  const line = [command, ...args].map((part) => `"${part}"`).join(" ");
  return spawnSync(line, { ...options, shell: true });
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
    // forces a fresh render below instead of crashing this setup.
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
      detail: `"${RSCRIPT}" is not on PATH (${tool.detail ?? "unknown error"}). Install R, or point BSLIBREACT_RSCRIPT at Rscript.`,
    };
  }

  const keyResult = run(RSCRIPT, [RENDER_R_SCRIPT, "--key"]);
  if (keyResult.error || keyResult.status !== 0) {
    return {
      state: "renderer-error",
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
      detail: `"${UV}" is not on PATH (${tool.detail ?? "unknown error"}). Install uv, or point BSLIBREACT_UV at it.`,
    };
  }

  const keyResult = run(UV, ["run", "python", RENDER_PY_SCRIPT, "--key"]);
  if (keyResult.error || keyResult.status !== 0) {
    return {
      state: "renderer-error",
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
  "renderer-error": "the catalog renderer failed",
};

function warnBanner(lang: Lang, status: CatalogLangStatus): void {
  const state = status.state;
  if (state === "ready") return;
  // Printing is the whole job of this function.
  // eslint-disable-next-line no-console
  console.warn(
    [
      "",
      `[bslibreact] markup catalog for "${lang}" is not ready: ${state}.`,
      `  ${STATE_EXPLAIN[state]}.`,
      status.detail ? `  ${status.detail}` : undefined,
      `  Every test that reads the "${lang}" catalog is SKIPPED this run.`,
      "  Set BSLIBREACT_REQUIRE_CATALOG=1 to make this a failure instead; CI does.",
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
    if (process.env.BSLIBREACT_REQUIRE_CATALOG === "1") {
      hardFailures.push(`${lang}: ${status.state}${status.detail ? ` - ${status.detail}` : ""}`);
    }
  }

  if (hardFailures.length > 0) {
    throw new Error(
      "BSLIBREACT_REQUIRE_CATALOG=1 is set, so a markup catalog that is not ready is " +
        `a hard failure, not a skip:\n  ${hardFailures.join("\n  ")}`,
    );
  }

  project.provide("bslibreactCatalog", statuses);
}
