import type { ReactNode } from "react";

type Props = { text: string; children: ReactNode };

/**
 * bslib::tooltip(). The web component reads template.content, which only
 * the browser's HTML parser fills in (a <template> parsed from a real
 * innerHTML string). Setting children through JSX would append them as
 * regular child nodes instead, which the component never reads, so the
 * text goes in through dangerouslySetInnerHTML.
 */
export function Tooltip({ text, children }: Props) {
  return (
    <bslib-tooltip
      placement="auto"
      bsOptions="[]"
      data-require-bs-version="5"
      data-require-bs-caller="tooltip()"
    >
      <template dangerouslySetInnerHTML={{ __html: text }} />
      {children}
    </bslib-tooltip>
  );
}
