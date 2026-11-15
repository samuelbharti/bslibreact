import type { ReactNode } from "react";
import { usePageBody } from "./usePageBody";

type Length = number | string;

type Props = {
  /** page_fillable(padding = ...): one to four lengths, as in CSS. An array
   *  stands for R's vector, so [0, 16] is "0px 16px". */
  padding?: Length | Length[];
  /** page_fillable(gap = ...): one length. */
  gap?: Length;
  children: ReactNode;
};

// bslib's rule for one length: a number, or a string that holds only a
// number, is pixels. Any other string is taken as a CSS length already.
function cssLength(value: Length) {
  if (typeof value === "number") return `${value}px`;
  const text = value.trim();
  return /^-?\d*\.?\d+$/.test(text) ? `${text}px` : text;
}

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
  if (padding != null) {
    style.padding = (Array.isArray(padding) ? padding : [padding]).map(cssLength).join(" ");
  }
  if (gap != null) style.gap = cssLength(gap);
  usePageBody("bslib-page-fill bslib-gap-spacing bslib-flow-mobile html-fill-container", style);

  return <>{children}</>;
}
