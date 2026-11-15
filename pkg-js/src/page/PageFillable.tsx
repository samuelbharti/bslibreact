import type { ReactNode } from "react";
import { usePageBody } from "./usePageBody";

type Props = {
  padding?: number;
  gap?: number;
  children: ReactNode;
};

/**
 * bslib::page_fillable(). Markup pinned against the `page_fillable` and
 * `page_fillable_default` catalog samples (bslib 0.12.0): the same body
 * fill classes as page_sidebar, minus bslib-page-sidebar. `padding` and
 * `gap` are in pixels. Like bslib, each one sets an inline style only when
 * it is given; left out, the theme's own spacing applies.
 */
export function PageFillable({ padding, gap, children }: Props) {
  const style: Record<string, string> = {};
  // != null: a plain JS client may pass null the way R passes NULL.
  if (padding != null) style.padding = `${padding}px`;
  if (gap != null) style.gap = `${gap}px`;
  usePageBody("bslib-page-fill bslib-gap-spacing bslib-flow-mobile html-fill-container", style);

  return <>{children}</>;
}
