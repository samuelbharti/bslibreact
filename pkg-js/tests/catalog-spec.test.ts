import { describe, expect, it } from "vitest";
import { catalogDoc, catalogLangs, loadCatalog, type Lang } from "./catalog";

/**
 * Checks each rendered catalog's own shape (docs/markup-catalog.md), for R
 * and for Python. markup.test.tsx compares the kit's components with the R
 * catalog; the Python catalog is checked only here: py-shiny renders some
 * markup differently from R bslib (no data-require-bs-* on cards, its own
 * navbar), so the components are not compared with it.
 */

// Every sample both catalogs must have: the R catalog minus R_ONLY.
// pkg-r's and pkg-py's own catalog tests each hold their language's list;
// renaming or dropping a sample is a deliberate edit in all three.
const REQUIRED_SAMPLES = [
  "selectInput",
  "selectizeInput",
  "radioButtons",
  "checkboxInput",
  "sliderInput",
  "actionButton",
  "selectizeInput_server_placeholder",
  "textAreaInput",
  "actionButton_class_override",
  "fileInput",
  "textInput",
  "actionLink",
  "downloadButton",
  "sliderInput_no_ticks",
  "selectizeInput_remove_button",
  "selectizeInput_max_options",
  "radioButtons_inline",
  "numericInput",
  "passwordInput",
  "checkboxGroupInput",
  "dateInput",
  "dateRangeInput",
  "input_dark_mode",
  "input_switch",
  "input_task_button",
  "plotOutput",
  "textOutput",
  "verbatimTextOutput",
  "plotOutput_click",
  "uiOutput",
  "uiOutput_fill",
  "uiOutput_inline",
  "card_full_screen",
  "card_bare_children",
  "card_footer",
  "card_id",
  "card_height",
  "card_no_fill",
  "value_box",
  "sidebar_layout",
  "sidebar_layout_titled",
  "sidebar_layout_right_closed",
  "sidebar_custom_class",
  "sidebar_layout_gap_padding",
  "accordion_checkbox_groups",
  "accordion",
  "layout_columns_value_box",
  "layout_columns_fill",
  "layout_columns_single_child",
  "tooltip",
  "popover",
  "navset_card_tab",
  "navset_pill",
  "details_summary",
  "helpText_hr",
  "page_fillable",
  "page_fillable_default",
  "page_navbar",
  "page_navbar_icon",
  "page_navbar_sidebar",
  "page_navbar_dropdown",
  "page_navbar_not_fillable",
] as const;

// The six samples only R can render: the five "extra" ones, which need DT,
// reactable, htmlwidgets or shinycssloaders, and "icon", which py-shiny
// has no helper for.
const R_ONLY = new Set([
  "DTOutput",
  "DTOutput_no_fill",
  "htmlwidget_output",
  "icon",
  "plotOutput_with_spinner",
  "reactableOutput",
]);

const VALID_KINDS = new Set(["tag", "page", "extra"]);
const VALID_GROUPS = new Set([
  "page",
  "nav",
  "layout",
  "card",
  "tooltip",
  "output",
  "input",
  "misc",
]);

// A sample name only has to read as a plain identifier - letters, digits,
// underscores, starting with a letter - not exclusively lowercase: the
// real names are a mix of bslib's own snake_case ("page_navbar") and R/
// shiny's historically camelCase function names ("selectInput",
// "DTOutput"), and the catalog intentionally keeps each sample named after
// the call it renders instead of normalising that away.
const VALID_NAME = /^[a-z][a-z0-9_]*$/i;

const EXPECTED_VERSION_KEYS: Record<Lang, string[]> = {
  r: ["bslib", "shiny", "htmltools", "runtime"],
  py: ["shiny", "htmltools", "bslib_vendored", "runtime"],
};

describe.each(catalogLangs())("catalog spec: %s", (lang: Lang) => {
  it("has schema 2", () => {
    expect(loadCatalog(lang).schema).toBe(2);
  });

  it("has a generator with a package name and version", () => {
    const { generator } = loadCatalog(lang);
    expect(typeof generator.package).toBe("string");
    expect(generator.package.length).toBeGreaterThan(0);
    expect(typeof generator.version).toBe("string");
    expect(generator.version.length).toBeGreaterThan(0);
  });

  it("has the expected version keys", () => {
    const { versions } = loadCatalog(lang);
    for (const key of EXPECTED_VERSION_KEYS[lang]) {
      expect(versions).toHaveProperty(key);
      expect(typeof versions[key]).toBe("string");
    }
  });

  it("every sample name is a plain identifier", () => {
    for (const name of Object.keys(loadCatalog(lang).samples)) {
      expect(name, `sample name ${JSON.stringify(name)} does not match ${VALID_NAME}`).toMatch(
        VALID_NAME,
      );
    }
  });

  it("every sample has a valid kind and group", () => {
    for (const [name, s] of Object.entries(loadCatalog(lang).samples)) {
      expect(
        VALID_KINDS.has(s.kind),
        `sample "${name}" has an unknown kind ${JSON.stringify(s.kind)}`,
      ).toBe(true);
      expect(
        VALID_GROUPS.has(s.group),
        `sample "${name}" has an unknown group ${JSON.stringify(s.group)}`,
      ).toBe(true);
    }
  });

  it("every sample's deps array is sorted and has no duplicates", () => {
    for (const [name, s] of Object.entries(loadCatalog(lang).samples)) {
      const sorted = [...s.deps].sort();
      expect(s.deps, `sample "${name}"'s deps are not sorted`).toEqual(sorted);
      expect(new Set(s.deps).size, `sample "${name}"'s deps contain a duplicate`).toBe(
        s.deps.length,
      );
    }
  });

  // The Bootstrap 3 nav markup a render without the bootstrapTheme option
  // gives (docs/markup-catalog.md, render rules) must never reach either
  // catalog: NavbarTabStrip is pinned to the Bootstrap 5 shape.
  it("renders page_navbar's tabs in Bootstrap 5 shape", () => {
    const doc = catalogDoc("page_navbar", lang);
    expect(doc.querySelector("li.nav-item > a.nav-link.active")).not.toBeNull();
    expect(doc.querySelector("li.active")).toBeNull();
  });

  it("includes every required sample name", () => {
    const known = new Set(Object.keys(loadCatalog(lang).samples));
    const missing = REQUIRED_SAMPLES.filter((name) => !known.has(name));
    expect(missing, `${lang} catalog is missing: ${missing.join(", ")}`).toEqual([]);
  });
});

const bothReady = catalogLangs().includes("r") && catalogLangs().includes("py");

describe.skipIf(!bothReady)("catalog spec: R and Python", () => {
  it("hold the same sample names, R-only samples aside", () => {
    const r = Object.keys(loadCatalog("r").samples).filter((name) => !R_ONLY.has(name));
    const py = Object.keys(loadCatalog("py").samples);
    expect(py.sort()).toEqual(r.sort());
  });
});
