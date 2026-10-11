// JSX typings for the web components bslib's own bundle registers. TSX can
// use <bslib-tooltip> the same way it uses any HTML tag once these are
// declared; the actual element implementation loads from the bslib
// component dependency the parent app already attaches to the page.
//
// This used to be custom-elements.d.ts, imported from index.ts only for its
// side effect (`import type {} from "./custom-elements"`), purely to pull
// the `declare module "react"` augmentation below into this package's own
// compilation. That worked inside this package, but broke the moment an
// app consumed the PUBLISHED npm package instead of this source tree:
// declaration emit only carries a file forward when something in the
// output actually references a named binding from it. An empty type-only
// import has no binding to carry, so tsc's emitted dist-npm/types/index.d.ts
// never mentioned custom-elements.d.ts at all, and <bslib-tooltip> stopped
// type-checking in a consuming app even though it still worked fine inside
// this package's own tests. Exporting real, named interfaces here, and
// re-exporting them with `export type {...} from "./custom-elements"` in
// index.ts (see that file's own comment), gives declaration emit an actual
// symbol to follow, which drags this whole module, ambient augmentation
// included, into the consuming app's compilation the same way importing
// any other type does.
import type { DetailedHTMLProps, HTMLAttributes, ReactNode } from "react";

/** Props for <bslib-tooltip> and <bslib-popover>: both are the same
 *  bslib web component shape (a placement, an options blob bslib itself
 *  renders as an empty-array string by default, and the two
 *  data-require-bs-* attributes every bslib component tag carries so the
 *  page's own dependency-discovery machinery knows which bslib component
 *  JS and Bootstrap version this element needs). */
export interface BslibTooltipProps extends DetailedHTMLProps<
  HTMLAttributes<HTMLElement>,
  HTMLElement
> {
  placement?: string;
  bsOptions?: string;
  "data-require-bs-version"?: string;
  "data-require-bs-caller"?: string;
}

/** Props for <bslib-layout-columns>. A custom element's own kebab-case
 *  attributes (class, col-widths-sm, ...) are not part of React's
 *  className-mapped HTMLAttributes, so they need their own literal keys
 *  rather than the usual camelCase props DetailedHTMLProps would offer. */
export interface BslibLayoutColumnsProps {
  id?: string;
  class?: string;
  "col-widths-sm"?: string;
  "data-require-bs-version"?: string;
  "data-require-bs-caller"?: string;
  children?: ReactNode;
}

/** Props for a bslib custom element with no shape of its own beyond plain
 *  HTML attributes (bslib-input-dark-mode, and the bslib-switch,
 *  bslib-switch-inline and bslib-offcanvas elements below).
 *
 *  This has to be a named, exported alias rather than
 *  `DetailedHTMLProps<HTMLAttributes<HTMLElement>, HTMLElement>` written
 *  inline at each property below: tsc's declaration emit for the
 *  `declare module "react"` augmentation prints each IntrinsicElements
 *  property's type as a standalone reference, and `DetailedHTMLProps` /
 *  `HTMLAttributes` are only locally imported into this file, not
 *  exported from it (TS4033, "has or is using private name"). A type
 *  that IS exported from this module, like BslibTooltipProps above, can
 *  be named directly in that emitted output; a bare import cannot. */
export type BslibElementProps = DetailedHTMLProps<HTMLAttributes<HTMLElement>, HTMLElement>;

// React 19's types nest JSX.IntrinsicElements inside the "react" module
// itself, not in a truly global JSX namespace, so augmenting "react" is
// what actually reaches <bslib-tooltip> in a .tsx file.
declare module "react" {
  namespace JSX {
    interface IntrinsicElements {
      "bslib-tooltip": BslibTooltipProps;
      "bslib-popover": BslibTooltipProps;
      "bslib-input-dark-mode": BslibElementProps;
      "bslib-layout-columns": BslibLayoutColumnsProps;
      // No component in this kit renders these yet, but bslib defines all
      // three: input_task_button() renders <bslib-switch-inline> and
      // <bslib-switch>, and offcanvas() renders <bslib-offcanvas>. Declared
      // so the same markup written by hand in TSX type-checks.
      "bslib-switch": BslibElementProps;
      "bslib-switch-inline": BslibElementProps;
      "bslib-offcanvas": BslibElementProps;
    }
  }
}
