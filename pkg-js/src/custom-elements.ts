// JSX types for the web components bslib's own JavaScript defines, so TSX
// can write <bslib-tooltip> and friends. index.ts re-exports the named prop
// types below; that is what makes tsc's declaration output carry this
// file's `declare module "react"` block to a consuming app (a type-only
// side-effect import would be dropped).
import type { DetailedHTMLProps, HTMLAttributes, ReactNode } from "react";

/** Props for <bslib-tooltip> and <bslib-popover>. */
export interface BslibTooltipProps extends DetailedHTMLProps<
  HTMLAttributes<HTMLElement>,
  HTMLElement
> {
  placement?: string;
  bsOptions?: string;
  "data-require-bs-version"?: string;
  "data-require-bs-caller"?: string;
}

/** Props for <bslib-layout-columns>, whose attributes (class,
 *  col-widths-sm) are not React's camelCase HTML props. */
export interface BslibLayoutColumnsProps {
  id?: string;
  class?: string;
  "col-widths-sm"?: string;
  "data-require-bs-version"?: string;
  "data-require-bs-caller"?: string;
  children?: ReactNode;
}

/** Props for a bslib element with plain HTML attributes only. A named,
 *  exported alias, since declaration output cannot name the locally
 *  imported DetailedHTMLProps inside `declare module` (TS4033). */
export type BslibElementProps = DetailedHTMLProps<HTMLAttributes<HTMLElement>, HTMLElement>;

// React 19 keeps JSX.IntrinsicElements inside the "react" module.
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
