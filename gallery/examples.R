# The gallery's registry: one entry per apps/<slug> directory. This is the
# single source of truth for app.R's sidebar; source code shown in the
# code panel is still read live from the real files in apps/<slug>/, never
# copied here, so it can never drift from what actually runs.

gallery_example <- function(slug, category, title, note) {
  list(slug = slug, category = category, title = title, note = note)
}

EXAMPLES <- list(
  gallery_example(
    "slider-input",
    "inputs",
    "Slider",
    "Dedicated component: SliderInput (hosts shiny::sliderInput())."
  ),
  gallery_example(
    "action-button",
    "inputs",
    "Action button",
    "Dedicated component: ActionButton (hosts shiny::actionButton())."
  ),
  gallery_example(
    "action-link",
    "inputs",
    "Action link",
    "Dedicated component: ActionLink (hosts shiny::actionLink())."
  ),
  gallery_example(
    "checkbox",
    "inputs",
    "Checkbox",
    "Dedicated component: CheckboxInput (hosts shiny::checkboxInput())."
  ),
  gallery_example(
    "dark-mode-switch",
    "inputs",
    "Dark mode switch",
    "Dedicated component: DarkModeInput (hosts bslib::input_dark_mode())."
  ),
  gallery_example(
    "download-button",
    "inputs",
    "Download button",
    "Dedicated component: DownloadButton (hosts shiny::downloadButton())."
  ),
  gallery_example(
    "file-input",
    "inputs",
    "File input",
    "Dedicated component: FileInput (hosts shiny::fileInput())."
  ),
  gallery_example(
    "numeric-input",
    "inputs",
    "Numeric input",
    "Dedicated component: NumericInput (hosts shiny::numericInput())."
  ),
  gallery_example(
    "password-field",
    "inputs",
    "Password field",
    "Dedicated component: PasswordInput (hosts shiny::passwordInput())."
  ),
  gallery_example(
    "plot-click",
    "inputs",
    "Plot (click input)",
    "Dedicated component: PlotOutput's own click prop (shiny::plotOutput(click=)), read server side with nearPoints()."
  ),
  gallery_example(
    "radio-buttons",
    "inputs",
    "Radio buttons",
    "Dedicated component: RadioButtons (hosts shiny::radioButtons())."
  ),
  gallery_example(
    "select-input",
    "inputs",
    "Select",
    "Dedicated component: SelectInput (hosts shiny::selectInput())."
  ),
  gallery_example(
    "select-multiple",
    "inputs",
    "Select (multiple)",
    "Dedicated component: SelectInput (hosts shiny::selectInput(multiple = TRUE))."
  ),
  gallery_example(
    "selectize-input",
    "inputs",
    "Selectize",
    "Dedicated component: SelectizeInput (hosts shiny::selectizeInput()), populated server side."
  ),
  gallery_example(
    "selectize-multiple",
    "inputs",
    "Selectize (multiple)",
    "Dedicated component: SelectizeInput (hosts shiny::selectizeInput(multiple = TRUE))."
  ),
  gallery_example(
    "text-area",
    "inputs",
    "Text area",
    "Dedicated component: TextAreaInput (hosts shiny::textAreaInput())."
  ),
  gallery_example(
    "text-box",
    "inputs",
    "Text box",
    "Dedicated component: TextInput (hosts shiny::textInput())."
  ),
  gallery_example(
    "switch-input",
    "inputs",
    "Switch",
    "No dedicated component yet: hosted through HostedInput, the same generic mechanism SliderInput itself is built on."
  ),
  gallery_example(
    "checkbox-group",
    "inputs",
    "Checkbox group",
    "No dedicated component yet: hosted through HostedInput."
  ),
  gallery_example(
    "date-selector",
    "inputs",
    "Date selector",
    "No dedicated component yet: hosted through HostedInput."
  ),
  gallery_example(
    "date-range",
    "inputs",
    "Date range selector",
    "No dedicated component yet: hosted through HostedInput."
  ),
  gallery_example(
    "slider-range",
    "inputs",
    "Slider range",
    "Dedicated component: SliderInput, the same one a single handle slider uses (hosts a two handle shiny::sliderInput())."
  ),
  gallery_example(
    "task-button",
    "inputs",
    "Task button",
    "No dedicated component yet: hosted through HostedInput."
  ),
  gallery_example(
    "download-link",
    "inputs",
    "Download link",
    "No dedicated component yet: hosted through HostedInput."
  ),
  gallery_example(
    "submit-button",
    "inputs",
    "Submit button",
    "A real limitation, not a bug: shiny::submitButton()'s hold-back-until-click behavior cannot work when the button is hosted. Shiny's client checks for the button once, at page load, before any hosted widget has rendered, so it never finds it and never defers sending. Values reach the server immediately instead of waiting for a click."
  ),

  gallery_example(
    "plot-output",
    "outputs",
    "Plot",
    "Dedicated component: PlotOutput (hosts shiny::plotOutput())."
  ),
  gallery_example(
    "value-box",
    "outputs",
    "Value box",
    "Dedicated component: ValueBox (reproduces bslib::value_box()), no input at all."
  ),
  gallery_example(
    "datatable",
    "outputs",
    "DataTable",
    "Dedicated component: DTOutput (hosts DT::DTOutput())."
  ),
  gallery_example(
    "table-reactable",
    "outputs",
    "Table (reactable)",
    "Dedicated component: ReactableOutput (hosts reactable::reactableOutput()). A real gotcha found here: reactable ships React itself through reactR under a dependency also named \"react\", which collided with page_react()'s own \"react\" dependency; fixed by renaming reactR's copy and loading it first."
  ),
  gallery_example(
    "image",
    "outputs",
    "Image",
    "shinyreact's own ImageOutput, which the kit re-exports: it draws its own <img> for renderImage()."
  ),
  gallery_example(
    "text-output",
    "outputs",
    "Text",
    "Dedicated component: TextOutput (hosts shiny::textOutput())."
  ),
  gallery_example(
    "ui-output",
    "outputs",
    "UI",
    "Dedicated component: UiOutput itself, the generic escape hatch for a whole dynamic shiny::renderUI() fragment."
  ),
  gallery_example(
    "verbatim-text",
    "outputs",
    "Verbatim text",
    "Dedicated component: VerbatimTextOutput (hosts shiny::verbatimTextOutput())."
  ),
  gallery_example(
    "map-leaflet",
    "outputs",
    "Map (leaflet)",
    "No dedicated component: WidgetOutput, the generic htmlwidget host, given widgetClass=\"leaflet\"."
  ),
  gallery_example(
    "plot-plotly",
    "outputs",
    "Plot (plotly)",
    "No dedicated component: WidgetOutput, the generic htmlwidget host, given widgetClass=\"plotly\"."
  ),
  gallery_example(
    "table-plain",
    "outputs",
    "Table",
    "No dedicated component: plain shiny::tableOutput() shares uiOutput()'s own binding, so UiOutput hosts it directly."
  ),
  gallery_example(
    "table-gt",
    "outputs",
    "Table (gt)",
    "No dedicated component: gt's output binding is plain HTML like uiOutput()'s, so UiOutput hosts it directly."
  ),

  gallery_example(
    "notification",
    "messages",
    "Notification",
    "No bslib-react display component: shiny::showNotification() renders through Shiny's own client JS, independent of the component tree."
  ),
  gallery_example(
    "tooltip",
    "messages",
    "Tooltip",
    "Dedicated component: Tooltip (reproduces bslib::tooltip() directly, not hosted)."
  ),
  gallery_example(
    "popover",
    "messages",
    "Popover",
    "No dedicated component: hosts the whole bslib::popover() call through UiOutput."
  ),
  gallery_example(
    "modal",
    "messages",
    "Modal",
    "No bslib-react display component: shiny::showModal() renders through Shiny's own client JS, the same discovery as Notification."
  ),
  gallery_example(
    "progress-bar",
    "messages",
    "Progress bar",
    "No bslib-react display component: shiny::withProgress()/incProgress() render through Shiny's own client JS, the same discovery as Notification and Modal."
  )
)

CATEGORIES <- list(
  list(key = "inputs", label = "Inputs"),
  list(key = "outputs", label = "Outputs"),
  list(key = "messages", label = "Display messages")
)
