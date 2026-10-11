import { ShinyOutput } from "../shinyreact";

type Props = { id: string };

/**
 * A traditional Shiny input widget (sliderInput, selectizeInput, and so
 * on), hosted rather than rebuilt in React. The server renders the
 * widget's own call through `renderUI()` (or `host_input()`), and this
 * shows that output: Shiny's own dynamic-UI binding loads the widget's
 * JS/CSS and binds it, so the widget behaves exactly as in a classic app.
 * shinyreact's maintainers recommend this over writing widget markup on
 * the client (posit-dev/shinyreact#286 and #294).
 *
 * `id` is the output's full name, `_ui` suffix included
 * (`<SliderInput id="bins_ui" />` for `output$bins_ui`), never the
 * widget's own input id: the output wrapper and the widget would then
 * share one DOM id. Inside a `<Module>`, `ShinyOutput` adds the namespace.
 *
 * `NavbarTabStrip.tsx`, and `LayoutSidebar` when given an `id`, still call
 * Shiny's binding functions themselves (through `useBoundScope`), since
 * each mixes Shiny-bound markup with React-owned content in a way
 * `renderUI()` cannot express; see their own file comments.
 */
export function HostedInput({ id }: Props) {
  return <ShinyOutput id={id} className="shiny-html-output" />;
}

// One name per Shiny widget, for readability at the call site. Each is
// HostedInput itself: the widget's options live only in the server call.

/** Hosts `shiny::actionButton()`. */
export const ActionButton = HostedInput;
/** Hosts `shiny::actionLink()`. */
export const ActionLink = HostedInput;
/** Hosts `shiny::checkboxInput()`. */
export const CheckboxInput = HostedInput;
/** Hosts `bslib::input_dark_mode()`, a `<bslib-input-dark-mode>` web
 *  component. Not yet checked in a browser since moving to HostedInput. */
export const DarkModeInput = HostedInput;
/** Hosts `shiny::downloadButton()`. */
export const DownloadButton = HostedInput;
/** Hosts `shiny::fileInput()`, uploads included (checked in the gallery). */
export const FileInput = HostedInput;
/** Hosts `shiny::numericInput()`. */
export const NumericInput = HostedInput;
/** Hosts `shiny::passwordInput()`. */
export const PasswordInput = HostedInput;
/** Hosts `shiny::radioButtons()`. */
export const RadioButtons = HostedInput;
/** Hosts `shiny::selectInput()`. */
export const SelectInput = HostedInput;
/** Hosts `shiny::selectizeInput()`. */
export const SelectizeInput = HostedInput;
/** Hosts `shiny::sliderInput()`, one or two handles. */
export const SliderInput = HostedInput;
/** Hosts `shiny::textAreaInput()`. */
export const TextAreaInput = HostedInput;
/** Hosts `shiny::textInput()`. */
export const TextInput = HostedInput;
