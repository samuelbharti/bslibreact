import { HostedInput } from "./HostedInput";

/**
 * shiny::sliderInput(). Hosted through the app's own
 * `output$<id> <- renderUI({ sliderInput(id, ...) })`, the shinyreact
 * team's recommended pattern for a traditional input widget (see
 * `HostedInput.tsx`'s own comment for the why). No widget props here on
 * purpose: min/max/value/step/ticks all live only in the R call, copied
 * verbatim from the parent, never duplicated in TSX to drift out of
 * sync.
 */
export const SliderInput = HostedInput;
