import { Children, type ReactNode } from "react";
import { cx } from "../cx";

type Props = {
  colWidths: number[];
  /** bslib::layout_columns()'s own default is TRUE. */
  fill?: boolean;
  /** layout_columns(class = "..."): an extra class on the outer element,
   *  e.g. variant-reviewer's own "vr-home-grid" (a CSS hook its app.css
   *  uses to widen the assistant's column on wide screens - see
   *  bslib::layout_columns(class = ...) rendering the class straight onto
   *  the same <bslib-layout-columns> tag, confirmed by dumping it from R). */
  className?: string;
  /** layout_columns(id = "..."): a caller-given id straight on the
   *  <bslib-layout-columns> tag itself (confirmed by dumping
   *  layout_columns(id = "x", ...) from R), usually a cicerone tour step
   *  target -- tahoe-explorer's own overview/about/qc pages each anchor a
   *  tour step to one. */
  id?: string;
  /** A single child is a real R shape too (variant-reviewer's own About
   *  page calls layout_columns(col_widths = 12, card(...)) four times, one
   *  card each) - Children.toArray() below normalizes either shape, since
   *  JSX only infers an array type for two or more children. */
  children: ReactNode | ReactNode[];
};

/**
 * bslib::layout_columns(). Markup pinned against the `layout_columns_value_box`
 * (fill = FALSE, bslib 0.12.0), `layout_columns_fill` (fill = TRUE, the R
 * default), and `layout_columns_single_child` catalog samples: a
 * <bslib-layout-columns> web component wrapping one .bslib-grid-item div
 * per child. col-widths-sm takes bslib's own comma-joined format. The two
 * fill samples differ only in one class on the outer tag: fill = TRUE adds
 * html-fill-item there; the grid-item children are identical either way.
 */
export function LayoutColumns({ colWidths, fill = true, className, id, children }: Props) {
  return (
    <bslib-layout-columns
      id={id}
      class={cx("bslib-grid grid bslib-mb-spacing", fill && "html-fill-item", className)}
      col-widths-sm={colWidths.join(",")}
      data-require-bs-version="5"
      data-require-bs-caller="layout_columns()"
    >
      {Children.toArray(children).map((child, i) => (
        <div key={i} className="bslib-grid-item bslib-gap-spacing html-fill-container">
          {child}
        </div>
      ))}
    </bslib-layout-columns>
  );
}
