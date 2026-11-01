import { Children, type ReactNode } from "react";
import { cx } from "../cx";

type Props = {
  colWidths: number[];
  /** bslib::layout_columns()'s own default is TRUE. */
  fill?: boolean;
  /** layout_columns(class = ...): an extra class on <bslib-layout-columns>. */
  className?: string;
  /** layout_columns(id = ...), on <bslib-layout-columns>. */
  id?: string;
  /** One child or many; each gets its own .bslib-grid-item wrapper. */
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
