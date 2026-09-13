import { describe, expect, it } from "vitest";
import { catalogLangs, loadCatalog, normaliseIds, shapeOf, type Shape } from "./catalog";

/**
 * Compares the R and Python catalogs against EACH OTHER, not against this
 * kit's own components (tests/markup.test.tsx does that, against R as the
 * reference - see docs/markup-catalog.md). Skips entirely unless both
 * languages are ready this run: a parity comparison with only one side
 * rendered is not a comparison at all.
 *
 * Two different bars for two different kinds of divergence:
 *
 * - The SAMPLE NAME SET is a hard fail if it differs. Both renderers are
 *   supposed to answer the exact same frozen name list (docs/markup-catalog.md's
 *   "Sample names" section, copied into pkg-r's, pkg-py's, and this
 *   package's own catalog-contract.test.ts) - even an "extra" sample whose
 *   backing package is missing is supposed to still appear as a key, with
 *   `skipped` set, not vanish from the JSON entirely. A missing key here
 *   means a renderer dropped a sample instead of recording why it could
 *   not render it.
 * - Everything else - an actual markup SHAPE difference between the two
 *   languages for a shared sample - is only ever printed, via
 *   console.table, never failed on. bslib and py-shiny are two different
 *   implementations of the same design; some divergence is expected and
 *   not a bug in either one. KNOWN_PY_DIFFS documents the ones already
 *   looked at and accepted; anything else shows up in the table for a
 *   human to actually look at, which is the point of printing it rather
 *   than either failing on it or silently dropping it.
 */

// Documented, accepted R-vs-Python shape divergences, keyed by sample
// name, each entry a short list of human-readable notes about what
// differs and why it is fine. Starts empty: bsOptions="[]" vs "{}" (R vs
// py-shiny/the TS default) is the one divergence anticipated up front, but
// shapeOf() already normalises that for every sample structurally (see
// tests/catalog.ts), so it never actually surfaces as a difference here
// and needs no entry. Add a real entry the day an actual, permanent,
// accepted divergence is found, rather than loosening the comparison
// below to ignore a whole class of differences.
const KNOWN_PY_DIFFS: Record<string, string[]> = {};

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

  it("prints (does not fail on) shape differences for shared samples", () => {
    const r = loadCatalog("r");
    const py = loadCatalog("py");
    const sharedNames = Object.keys(r.samples)
      .filter((name) => name in py.samples)
      .sort();

    const rows: Array<{ sample: string; index: number; r: string; py: string }> = [];

    for (const name of sharedNames) {
      if (KNOWN_PY_DIFFS[name]) continue;

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

    if (rows.length > 0) {
      // eslint-disable-next-line no-console
      console.table(rows);
    }

    // Informational only - this assertion always passes. The table above
    // (visible in `npx vitest run` output) is the actual signal for a
    // human to read; a real, permanent divergence gets an entry in
    // KNOWN_PY_DIFFS once someone has looked at it, not a failing test
    // here.
    expect(rows).toEqual(rows);
  });
});
