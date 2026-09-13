// Join class names, dropping falsy ones. No dependency, and the args stay
// readable at the call site: cx("card", fill && "html-fill-container").
export function cx(...parts: Array<string | false | null | undefined>): string {
  return parts.filter(Boolean).join(" ");
}
