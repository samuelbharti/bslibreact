import type { ReactNode } from "react";
import { usePageBody } from "./usePageBody";

type Props = {
  /** page_fillable(padding = ...): a number is pixels, a string is any CSS
   *  length, such as "1rem" or "0 16px". */
  padding?: number | string;
  /** page_fillable(gap = ...): a number is pixels, a string is any CSS length. */
  gap?: number | string;
  children: ReactNode;
};

// What bslib does with the same arguments: a number becomes pixels, and a
// string is already a CSS length.
const cssLength = (value: number | string) => (typeof value === "number" ? `${value}px` : value);

/**
 * bslib::page_fillable(). Markup pinned against the `page_fillable` and
 * `page_fillable_default` catalog samples (bslib 0.12.0): the same body
 * fill classes as page_sidebar, minus bslib-page-sidebar. Like bslib,
 * `padding` and `gap` each set an inline style only when given; left out,
 * the theme's own spacing applies.
 */
export function PageFillable({ padding, gap, children }: Props) {
  const style: Record<string, string> = {};
  // != null: a plain JS client may pass null the way R passes NULL.
  if (padding != null) style.padding = cssLength(padding);
  if (gap != null) style.gap = cssLength(gap);
  usePageBody("bslib-page-fill bslib-gap-spacing bslib-flow-mobile html-fill-container", style);

  return <>{children}</>;
}
