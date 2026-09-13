import { HostedInput } from "./HostedInput";

/**
 * bslib::input_dark_mode(). Hosted through the app's own
 * `output$<id> <- renderUI({ bslib::input_dark_mode(id = id) })`; see
 * `HostedInput.tsx`'s own comment for why. A `<bslib-input-dark-mode>`
 * web component, not a standard form control -- its own
 * `connectedCallback()` should initialize it regardless of how it
 * entered the DOM, so hosting it this way is expected to work the same
 * as a plain shiny:: widget, but this is the first time it has been
 * re-checked since migrating off the hand-written ShinyInput host.
 * Re-verify against a running app before trusting it blindly.
 */
export const DarkModeInput = HostedInput;
