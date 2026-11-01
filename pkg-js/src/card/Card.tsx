import { useId, useLayoutEffect, type CSSProperties, type ReactNode } from "react";
import { cx } from "../cx";
import { Tooltip } from "../tooltip/Tooltip";

type CardProps = {
  fullScreen?: boolean;
  fill?: boolean;
  height?: string;
  className?: string;
  /** card(id = ...). Adds bslib-card-input, as bslib does; without it a
   *  non-full-screen card has no id. */
  id?: string;
  children: ReactNode;
};

const EXPAND_ICON_PATH =
  "M20 5C20 4.4 19.6 4 19 4H13C12.4 4 12 3.6 12 3C12 2.4 12.4 2 13 2H21C21.6 2 22 2.4 22 3V11C22 11.6 21.6 12 21 12C20.4 12 20 11.6 20 11V5ZM4 19C4 19.6 4.4 20 5 20H11C11.6 20 12 20.4 12 21C12 21.6 11.6 22 11 22H3C2.4 22 2 21.6 2 21V13C2 12.4 2.4 12 3 12C3.6 12 4 12.4 4 13V19Z";

/**
 * bslib::card(). Markup pinned against the "card_full_screen", "card_id",
 * and "card_no_fill" catalog samples (bslib 0.12.0). A card renders its own
 * inline script that calls bslib.Card.initializeAllCards() to wire up
 * full-screen and fill behavior; a <script> inside JSX never runs, so the
 * same call happens from an effect instead, once the card is in the DOM.
 * The call is idempotent (it only touches cards still carrying
 * data-bslib-card-init).
 */
export function Card({
  fullScreen = false,
  fill = true,
  height,
  className,
  id,
  children,
}: CardProps) {
  // bslib gives a card an automatic id only when full_screen = TRUE.
  const cardId = useId();

  useLayoutEffect(() => {
    window.bslib?.Card?.initializeAllCards();
  }, []);

  const style: CSSProperties | undefined = height ? { height } : undefined;

  return (
    <div
      id={id ?? (fullScreen ? `bslib-card-${cardId}` : undefined)}
      className={cx(
        "card bslib-card bslib-mb-spacing html-fill-container",
        id && "bslib-card-input",
        // html-fill-container always (a card fills its own children);
        // html-fill-item only when the card itself fills its parent.
        fill && "html-fill-item",
        className,
      )}
      data-bslib-card-init=""
      data-full-screen={fullScreen ? "false" : undefined}
      data-require-bs-caller="card()"
      data-require-bs-version="5"
      style={style}
    >
      {children}
      {fullScreen && (
        <Tooltip text="Expand">
          <button
            aria-expanded="false"
            aria-label="Expand card"
            className="bslib-full-screen-enter badge rounded-pill"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              style={{ height: "1em", width: "1em", fill: "currentColor" }}
              aria-hidden="true"
              role="img"
            >
              <path d={EXPAND_ICON_PATH} />
            </svg>
          </button>
        </Tooltip>
      )}
    </div>
  );
}

export function CardHeader({
  className,
  id,
  children,
}: {
  className?: string;
  /** card_header(id = ...). */
  id?: string;
  children: ReactNode;
}) {
  return (
    <div className={cx("card-header bslib-gap-spacing", className)} id={id}>
      {children}
    </div>
  );
}

export function CardBody({
  fill = true,
  className,
  style,
  html,
  children,
}: {
  fill?: boolean;
  className?: string;
  style?: CSSProperties;
  /** Raw HTML (bslib::markdown() output, say), instead of children. */
  html?: string;
  children?: ReactNode;
}) {
  return (
    <div
      className={cx(
        "card-body bslib-gap-spacing html-fill-item",
        fill && "html-fill-container",
        className,
      )}
      style={{ marginTop: "auto", marginBottom: "auto", flex: "1 1 auto", ...style }}
      {...(html !== undefined ? { dangerouslySetInnerHTML: { __html: html } } : {})}
    >
      {html === undefined ? children : undefined}
    </div>
  );
}

export function CardFooter({ className, children }: { className?: string; children: ReactNode }) {
  return <div className={cx("card-footer", className)}>{children}</div>;
}
