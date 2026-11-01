import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import { catalogLangs, loadCatalog, normaliseIds, shapeOf, type Shape } from "./catalog";

// Sample:index pairs that already differ between the two catalogs.
const BASELINE_PATH = join(dirname(fileURLToPath(import.meta.url)), "parity-baseline.json");

/**
 * Compares the R and Python catalogs with each other (markup.test.tsx
 * compares the kit's components with the R one). Runs only when both are
 * ready. The two catalogs must hold the same sample names, R-only samples
 * aside. Shape differences between them are recorded in
 * parity-baseline.json, and the test fails only when a new one appears.
 */

// Sample names that exist only in the R catalog because plain shiny plus
// htmltools has no call that produces them at all: py-shiny has no
// built-in icon helper analogous to shiny::icon(), and DT, reactable,
// htmlwidgets, and shinycssloaders are R-only packages with no Python
// catalog entry to skip in the first place. See
// pkg-py/src/bslib_react/_catalog.py's own module docstring for the
// per-name reasoning, and catalog-contract.test.ts's REQUIRED_SAMPLES
// comment for the same exclusion applied there. This is the one
// documented, permanent divergence in the sample name set; anything else
// only on one side is a real gap the test below should still catch.
const NOT_IN_PYTHON = new Set([
  "DTOutput",
  "DTOutput_no_fill",
  "htmlwidget_output",
  "icon",
  "plotOutput_with_spinner",
  "reactableOutput",
]);

// "Comparable" mirrors the plan this test exists to check: bslib's and
// shinyreact's own markup, not every last Bootstrap utility class an app
// author might add. `startsWith`, not an exact match, so "card-header",
// "nav-link", and "html-fill-container" are all covered by their shorter
// prefixes here.
const COMPARABLE_PREFIXES = ["bslib-", "card", "nav", "tab-", "sidebar", "shiny-", "html-fill"];

function isComparableClass(cls: string): boolean {
  return COMPARABLE_PREFIXES.some((prefix) => cls.startsWith(prefix));
}

function comparableElements(html: string): Element[] {
  const doc = new DOMParser().parseFromString(normaliseIds(html), "text/html");
  return Array.from(doc.querySelectorAll("*")).filter((el) =>
    Array.from(el.classList).some(isComparableClass),
  );
}

/** Order-independent equality for a Shape (or null): shapeOf()'s own
 *  arrays are already sorted, but a plain JSON.stringify comparison would
 *  still report a false difference if the two sides' `attrs` records
 *  happened to have their keys in a different insertion order, which R and
 *  Python's own attribute emission order gives no guarantee against. */
function stableStringify(value: unknown): string {
  if (Array.isArray(value)) {
    return `[${value.map(stableStringify).join(",")}]`;
  }
  if (value && typeof value === "object") {
    const record = value as Record<string, unknown>;
    const keys = Object.keys(record).sort();
    return `{${keys.map((k) => `${JSON.stringify(k)}:${stableStringify(record[k])}`).join(",")}}`;
  }
  return JSON.stringify(value);
}

function shapesEqual(a: Shape | null, b: Shape | null): boolean {
  return stableStringify(a) === stableStringify(b);
}

const langs = catalogLangs();
const bothReady = langs.includes("r") && langs.includes("py");

describe.skipIf(!bothReady)("parity: R vs Python catalog", () => {
  it("render the exact same sample names", () => {
    const rNames = new Set(Object.keys(loadCatalog("r").samples));
    const pyNames = new Set(Object.keys(loadCatalog("py").samples));
    const onlyR = Array.from(rNames)
      .filter((n) => !pyNames.has(n) && !NOT_IN_PYTHON.has(n))
      .sort();
    const onlyPy = Array.from(pyNames)
      .filter((n) => !rNames.has(n))
      .sort();
    expect({ onlyR, onlyPy }).toEqual({ onlyR: [], onlyPy: [] });
  });

  it("grows no new R vs Python shape differences", () => {
    const r = loadCatalog("r");
    const py = loadCatalog("py");
    const sharedNames = Object.keys(r.samples)
      .filter((name) => name in py.samples)
      .sort();

    const rows: Array<{ sample: string; index: number; r: string; py: string }> = [];

    for (const name of sharedNames) {
      const rSample = r.samples[name]!;
      const pySample = py.samples[name]!;
      if (rSample.skipped || pySample.skipped) continue;

      const rEls = comparableElements(rSample.html);
      const pyEls = comparableElements(pySample.html);
      const max = Math.max(rEls.length, pyEls.length);

      for (let i = 0; i < max; i++) {
        const rShape = shapeOf(rEls[i] ?? null);
        const pyShape = shapeOf(pyEls[i] ?? null);
        if (!shapesEqual(rShape, pyShape)) {
          rows.push({
            sample: name,
            index: i,
            r: JSON.stringify(rShape),
            py: JSON.stringify(pyShape),
          });
        }
      }
    }

    const current = rows.map((row) => `${row.sample}:${row.index}`).sort();

    // Regenerate the baseline with PARITY_UPDATE_BASELINE=1 after a
    // deliberate change, and read the printed table before you do.
    if (process.env.PARITY_UPDATE_BASELINE === "1") {
      writeFileSync(
        BASELINE_PATH,
        `${JSON.stringify(current, null, 2)}
`,
      );
      return;
    }

    const baseline: string[] = existsSync(BASELINE_PATH)
      ? JSON.parse(readFileSync(BASELINE_PATH, "utf8"))
      : [];
    const baselineSet = new Set(baseline);
    const appeared = current.filter((key) => !baselineSet.has(key));

    if (appeared.length > 0) {
      // eslint-disable-next-line no-console
      console.table(rows.filter((row) => appeared.includes(`${row.sample}:${row.index}`)));
    }

    expect(appeared).toEqual([]);

    const currentSet = new Set(current);
    const resolved = baseline.filter((key) => !currentSet.has(key));
    if (resolved.length > 0) {
      // Not a failure: upstream moves, and a divergence going away is
      // good news. Shrink the baseline so it keeps meaning something.
      // eslint-disable-next-line no-console
      console.warn(
        `parity baseline has ${resolved.length} stale entr${resolved.length === 1 ? "y" : "ies"}; ` +
          `rerun with PARITY_UPDATE_BASELINE=1 to shrink it: ${resolved.join(", ")}`,
      );
    }
  });
});
