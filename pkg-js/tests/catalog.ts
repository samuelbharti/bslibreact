import { readFileSync } from "node:fs";
import type { ReactElement } from "react";
import { render } from "@testing-library/react";
import { describe, inject } from "vitest";
import type { CatalogLangStatus } from "./global-setup";

/**
 * Reads the markup catalogs `tests/global-setup.ts` rendered (or found
 * already fresh in `.cache/markup/`) and turns a catalog sample's raw HTML
 * into the same comparable "shape" the old fixture-based tests compared
 * against (see the shinyreact-apps `tests/fixture.ts` this replaces). The
 * catalog is the ground truth now, not a committed file: see
 * docs/markup-catalog.md at the repo root for the full contract this file
 * codes against, and decisions/0001-no-fixtures-live-ground-truth.md for
 * why.
 *
 * Every test-facing function here (`sample`, `catalogDoc`, `catalogShape`,
 * `catalogClasses`, `loadCatalog`) throws if the requested language's
 * catalog is not ready. Call `catalogLangs()` or `describeCatalog()` first,
 * the same way every markup test in this package does, rather than calling
 * these directly on a language that might not be ready.
 */

export type Lang = "r" | "py";

export type SampleKind = "tag" | "page" | "extra";
export type SampleGroup =
  "page" | "nav" | "layout" | "card" | "tooltip" | "output" | "input" | "misc";

export type CatalogSample = {
  kind: SampleKind;
  group: SampleGroup;
  /** True for a "page" sample actually served through a running app
   *  (`served: false` records a renderTags()-only fallback; see
   *  docs/markup-catalog.md's render rules for "page"). */
  served: boolean;
  /** The exact R or Python call this sample renders, for a human reading
   *  a failing test to reproduce by hand. */
  call: string;
  /** Raw HTML. Neither renderer normalises anything - see normaliseIds()
   *  below for the one place that happens. */
  html: string;
  /** Served pages only: attributes of the served document's <html>. */
  html_attrs: Record<string, string> | null;
  /** Served pages only: the text of every <style> block found in <head>. */
  head_inline_css: string[];
  /** htmlDependency names/versions the sample's markup declares. */
  deps: string[];
  /** "extra" samples only: why this sample was not rendered (the backing
   *  package is not installed), or null when it rendered normally. */
  skipped: string | null;
};

export type Catalog = {
  schema: 1;
  language: Lang;
  key: string;
  generated_at: string;
  generator: { package: string; version: string };
  versions: Record<string, string>;
  samples: Record<string, CatalogSample>;
};

export type Shape = {
  tag: string;
  classes: string[];
  attrs: Record<string, string>;
  /** Present only when the element carries a style attribute at all: a
   *  sorted list of "prop:value" (or "prop:value !important") strings,
   *  read back through the parsed CSSStyleDeclaration rather than compared
   *  as a literal string, so declaration order and incidental whitespace
   *  never fail a test that does not care about either. */
  style?: string[];
};

/** Attributes whose values are minted fresh per render (a random id, or
 *  something derived from one), so never comparable across two renders of
 *  the same call, let alone between R and Python. See
 *  docs/markup-catalog.md's "Id normalisation" section. */
export const VOLATILE: Set<string> = new Set([
  "id",
  "for",
  "href",
  "data-target",
  "data-bs-target",
  "aria-controls",
  "aria-labelledby",
  "data-tabsetid",
]);

type IdPattern = {
  pattern: RegExp;
  replace: (substring: string, ...groups: string[]) => string;
};

/**
 * The four id-normalisation patterns from docs/markup-catalog.md, applied
 * to a sample's raw `html` STRING before it is parsed (see normaliseIds()).
 * bslib mints these from Shiny's own private RNG, which cannot be seeded;
 * py-shiny mints its own, in a different format (R favors hyphens
 * throughout, e.g. "bslib-card-3f8a1c2b"; py-shiny's ids are hex with
 * underscores). The `[-_]` alternation in the first two patterns matches
 * either; the replacer functions (rather than a plain "$1"-style backref)
 * additionally normalise the CAPTURED separator itself to a hyphen, so
 * "accordion-panel" and "accordion_panel" collapse to the exact same
 * normalised string - otherwise a difference in separator convention alone
 * would look like a real markup divergence to tests/parity.test.ts.
 *
 * The trailing `\b` on the first two patterns is load-bearing, not
 * decorative: `[0-9a-f]+` is greedy but has no minimum-length requirement
 * beyond one character, and "b", "a", "c", "d", "e", and "f" are all valid
 * hex digits on their own. Without a word boundary forcing the match to
 * end where the surrounding word actually ends, `bslib[-_]sidebar[-_]` in
 * the attribute NAME "data-bslib-sidebar-border" (no random id involved at
 * all) matched "bslib-sidebar-b" - just the leading "b" of "border" - and
 * replaced it with "bslib-sidebar-ID", corrupting the attribute name into
 * "data-bslib-sidebar-IDorder". `\b` after the hex run forces the engine to
 * keep matching hex digits until a real word boundary, which "border" (an
 * all-letters, non-hex tail after that first "b") can never satisfy, so
 * the pattern simply does not match there at all - while a genuine id like
 * "bslib-sidebar-2225", followed by a quote, satisfies the boundary
 * immediately and matches exactly as intended.
 */
export const ID_PATTERNS: IdPattern[] = [
  {
    pattern: /bslib[-_](card|sidebar|accordion[-_]panel|accordion)[-_][0-9a-f]+\b/g,
    replace: (_match, kind) => `bslib-${kind.replace(/[-_]/g, "-")}-ID`,
  },
  {
    pattern: /navbar[-_]collapse[-_][0-9a-f]+\b/g,
    replace: () => "navbar-collapse-ID",
  },
  {
    pattern: /data-tabsetid="[0-9a-f]+"/g,
    replace: () => `data-tabsetid="ID"`,
  },
  {
    pattern: /tab-[0-9a-f]+-(\d+)/g,
    replace: (_match, n) => `tab-ID-${n}`,
  },
];

/** Apply every ID_PATTERNS replacement to a raw catalog sample's html,
 *  before parsing it. The cache file itself is never touched - it stays a
 *  faithful record of exactly what bslib or py-shiny emitted, which is
 *  what you want to read when a test fails and you go look at the file. */
export function normaliseIds(html: string): string {
  return ID_PATTERNS.reduce((acc, { pattern, replace }) => acc.replace(pattern, replace), html);
}

/** This language's catalog status, as tests/global-setup.ts decided it for
 *  this run. Ready, or one of the reasons it is not (see that file's own
 *  CatalogState doc comment). */
export function catalogStatus(lang: Lang): CatalogLangStatus {
  return inject("bslibReactCatalog")[lang];
}

/** Every language whose catalog is ready to read this run. Check this (or
 *  use describeCatalog(), which does) before calling loadCatalog(), sample(),
 *  catalogDoc(), catalogShape(), or catalogClasses(). */
export function catalogLangs(): Lang[] {
  return (["r", "py"] as const).filter((lang) => catalogStatus(lang).state === "ready");
}

const catalogCache = new Map<Lang, Catalog>();

/** Read and parse `lang`'s catalog file, memoized for the life of this test
 *  run (every test in every file reads the same object, not a fresh
 *  JSON.parse per call). Throws a clear error if the catalog is not
 *  "ready" - callers should check catalogLangs() / describeCatalog() first
 *  rather than reaching here on a language that might not be available. */
export function loadCatalog(lang: Lang): Catalog {
  const cached = catalogCache.get(lang);
  if (cached) return cached;

  const status = catalogStatus(lang);
  if (status.state !== "ready") {
    throw new Error(
      `loadCatalog("${lang}"): the ${lang} catalog is not ready (${status.state}). ` +
        "Check catalogLangs() or wrap the test in describeCatalog() instead of calling " +
        "loadCatalog() unconditionally." +
        (status.detail ? ` Detail: ${status.detail}` : ""),
    );
  }

  const parsed = JSON.parse(readFileSync(status.path, "utf8")) as Catalog;
  if (parsed.schema !== 1) {
    throw new Error(
      `loadCatalog("${lang}"): ${status.path} has schema ${JSON.stringify(parsed.schema)}, this ` +
        "package only understands schema 1. Was it rendered by a newer, incompatible renderer?",
    );
  }
  catalogCache.set(lang, parsed);
  return parsed;
}

/** One named sample from `lang`'s catalog. Throws, listing every known
 *  sample name, on a typo - a silent `undefined` here would otherwise turn
 *  into a much less clear crash a few calls further down. */
export function sample(name: string, lang: Lang = "r"): CatalogSample {
  const catalog = loadCatalog(lang);
  const found = catalog.samples[name];
  if (!found) {
    const known = Object.keys(catalog.samples).sort();
    throw new Error(
      `sample(${JSON.stringify(name)}, ${JSON.stringify(lang)}): no such sample. ` +
        `Known sample names:\n  ${known.join("\n  ")}`,
    );
  }
  return found;
}

/** Parse a sample's (id-normalised) html into a Document. */
export function catalogDoc(name: string, lang: Lang = "r"): Document {
  const { html } = sample(name, lang);
  return new DOMParser().parseFromString(normaliseIds(html), "text/html");
}

/** The comparable shape of one element: tag, sorted classes, stable attrs,
 *  and (when present) a sorted list of inline style declarations. Mirrors
 *  the old fixture.ts's shapeOf(), plus the style comparison the fixture
 *  version never needed (see docs/markup-catalog.md's own note on why
 *  `style` is compared as a parsed, sorted list rather than a literal
 *  string). */
export function shapeOf(el: Element | null): Shape | null {
  if (!el) return null;

  const attrs: Record<string, string> = {};
  for (const a of Array.from(el.attributes)) {
    if (a.name === "class" || a.name === "style" || VOLATILE.has(a.name)) continue;
    // R renders bsOptions="[]" for "no options"; the TS default and
    // py-shiny both use "{}". Both mean the same thing, so they must
    // compare equal. Attribute names come back lower-cased from the DOM
    // (setAttribute and HTML parsing both fold ASCII case), so "bsoptions"
    // is the only casing that ever actually shows up here.
    const value = a.name === "bsoptions" && (a.value === "[]" || a.value === "{}") ? "[]" : a.value;
    attrs[a.name] = value;
  }

  const shape: Shape = {
    tag: el.tagName.toLowerCase(),
    classes: Array.from(el.classList).sort(),
    attrs,
  };

  if (el.hasAttribute("style")) {
    const style = (el as HTMLElement).style;
    const declarations: string[] = [];
    for (let i = 0; i < style.length; i++) {
      const prop = style.item(i);
      const priority = style.getPropertyPriority(prop);
      declarations.push(
        `${prop}:${style.getPropertyValue(prop)}${priority ? ` !${priority}` : ""}`,
      );
    }
    shape.style = declarations.sort();
  }

  return shape;
}

/** The shape of the first element matching `selector`, from one catalog
 *  sample. `null` when nothing matches, same as a bare querySelector(). */
export function catalogShape(name: string, selector: string, lang: Lang = "r"): Shape | null {
  return shapeOf(catalogDoc(name, lang).querySelector(selector));
}

/** Every class bslib (or py-shiny) puts on the first element matching
 *  `selector`, so a missing one fails loudly instead of comparing an empty
 *  list against an empty list. Throws, unlike catalogShape(), because a
 *  selector that matches nothing is always a mistake in a test that is
 *  specifically asking "what classes does this element have". */
export function catalogClasses(name: string, selector: string, lang: Lang = "r"): string[] {
  const el = catalogDoc(name, lang).querySelector(selector);
  if (!el) {
    throw new Error(
      `catalogClasses(${JSON.stringify(name)}, ${JSON.stringify(selector)}, ${JSON.stringify(lang)}): ` +
        `nothing matched "${selector}"`,
    );
  }
  return Array.from(el.classList).sort();
}

/** Render a kit component and read back the shape of the first element
 *  matching `selector`, the other half of every comparison in
 *  tests/markup.test.tsx (catalogShape() reads what bslib/py-shiny
 *  produced; this reads what the kit produced from the same call shape). */
export function renderShape(ui: ReactElement, selector: string): Shape | null {
  const { container } = render(ui);
  return shapeOf(container.querySelector(selector));
}

/**
 * A `describe` wrapper that skips the whole block, with the reason in the
 * title, when `lang`'s catalog is not ready. Every markup test in this
 * package that reads the catalog is wrapped in this instead of a bare
 * `describe`, so a `vitest run` with no R or Python installed reports
 * "SKIPPED: NavbarTabStrip (skipped: r catalog is missing-tool)" rather
 * than a wall of throws from `sample()`/`loadCatalog()`.
 */
export function describeCatalog(lang: Lang, name: string, fn: () => void): void {
  const ready = catalogLangs().includes(lang);
  const status = catalogStatus(lang);
  const title = ready ? name : `${name} (skipped: ${lang} catalog is ${status.state})`;
  describe.skipIf(!ready)(title, fn);
}
