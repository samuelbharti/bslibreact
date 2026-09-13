import { HostedInput } from "./HostedInput";

/**
 * shiny::actionLink(). Hosted through the app's own
 * `output$<id> <- renderUI({ actionLink(id, ...) })`; see
 * `HostedInput.tsx`'s own comment for why. No label/icon/class props
 * here, including an icon in the label
 * (`actionLink(id, label = tagList(icon("..."), "text"))`): all of it
 * lives only in the R call, copied verbatim from the parent.
 */
export const ActionLink = HostedInput;
