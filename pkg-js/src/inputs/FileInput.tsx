import { HostedInput } from "./HostedInput";

/**
 * shiny::fileInput(). Hosted through the app's own
 * `output$<id> <- renderUI({ fileInput(id, ...) })`; see
 * `HostedInput.tsx`'s own comment for why. No label/accept props here:
 * those live only in the R call, copied verbatim from the parent.
 *
 * Verified against a running app, which matters more here than for the
 * other hosted inputs: fileInput()'s own binding does more than read a
 * value, it posts the file's bytes to a dedicated upload endpoint. The
 * gallery's file-input example was driven with a real file, the progress
 * bar reached "Upload complete", and the server read back the uploaded
 * name through input$upload$name.
 */
export const FileInput = HostedInput;
