import type { ReactNode } from "react";
import { usePageBody } from "./usePageBody";

type Props = {
  padding?: number;
  gap?: number;
  children: ReactNode;
};

/**
 * bslib::page_fillable(). Markup pinned against the `page_fillable` catalog
 * sample (bslib 0.12.0): the same body fill classes as page_sidebar, minus
 * bslib-page-sidebar, with padding/gap from the call's own arguments
 * instead of the default 0.
 */
export function PageFillable({ padding = 12, gap = 12, children }: Props) {
  usePageBody("bslib-page-fill bslib-gap-spacing bslib-flow-mobile html-fill-container", {
    padding: `${padding}px`,
    gap: `${gap}px`,
  });

  return <>{children}</>;
}
