# The gallery's registry: one entry per apps/<slug> directory. This is the
# single source of truth for app.R's sidebar; source code shown in the
# code panel is still read live from the real files in apps/<slug>/, never
# copied here, so it can never drift from what actually runs.

sample <- function(slug, category, title, note) {
  list(slug = slug, category = category, title = title, note = note)
}

EXAMPLES <- list(
  sample(
    "slider-input",
    "inputs",
    "Slider",
    "Dedicated component: SliderInput (hosts shiny::sliderInput())."
  ),
  sample(
    "action-button",
    "inputs",
    "Action button",
    "Dedicated component: ActionButton (hosts shiny::actionButton())."
  ),
  sample(
    "action-link",
    "inputs",
    "Action link",
    "Dedicated component: ActionLink (hosts shiny::actionLink())."
  ),
  sample(
    "checkbox",
    "inputs",
    "Checkbox",
    "Dedicated component: CheckboxInput (hosts shiny::checkboxInput())."
  ),
  sample(
    "dark-mode-switch",
    "inputs",
    "Dark mode switch",
    "Dedicated component: DarkModeInput (hosts bslib::input_dark_mode())."
  ),
  sample(
    "download-button",
    "inputs",
    "Download button",
    "Dedicated component: DownloadButton (hosts shiny::downloadButton())."
  ),
  sample(
    "file-input",
    "inputs",
    "File input",
    "Dedicated component: FileInput (hosts shiny::fileInput())."
  ),
  sample(
    "numeric-input",
    "inputs",
    "Numeric input",
    "Dedicated component: NumericInput (hosts shiny::numericInput())."
  ),
  sample(
    "password-field",
    "inputs",
    "Password field",
    "Dedicated component: PasswordInput (hosts shiny::passwordInput())."
  ),
  sample(
    "plot-click",
    "inputs",
    "Plot (click input)",
    "Dedicated component: PlotOutput's own click prop (shiny::plotOutput(click=)), read server side with nearPoints()."
  ),
  sample(
    "radio-buttons",
    "inputs",
    "Radio buttons",
    "Dedicated component: RadioButtons (hosts shiny::radioButtons())."
  ),
  sample(
    "select-input",
    "inputs",
    "Select",
    "Dedicated component: SelectInput (hosts shiny::selectInput())."
  ),
  sample(
    "select-multiple",
    "inputs",
    "Select (multiple)",
    "Dedicated component: SelectInput (hosts shiny::selectInput(multiple = TRUE))."
  ),
  sample(
    "selectize-input",
    "inputs",
    "Selectize",
    "Dedicated component: SelectizeInput (hosts shiny::selectizeInput()), populated server side."
  ),
  sample(
    "selectize-multiple",
    "inputs",
    "Selectize (multiple)",
    "Dedicated component: SelectizeInput (hosts shiny::selectizeInput(multiple = TRUE))."
  ),
  sample(
    "text-area",
    "inputs",
    "Text area",
    "Dedicated component: TextAreaInput (hosts shiny::textAreaInput())."
  ),
  sample(
    "text-box",
    "inputs",
    "Text box",
    "Dedicated component: TextInput (hosts shiny::textInput())."
  ),
  sample(
    "switch-input",
    "inputs",
    "Switch",
    "No dedicated component yet: hosted through HostedInput, the same generic mechanism SliderInput itself is built on."
  ),
  sample(
    "checkbox-group",
    "inputs",
    "Checkbox group",
    "No dedicated component yet: hosted through HostedInput."
  ),
  sample(
    "date-selector",
    "inputs",
    "Date selector",
    "No dedicated component yet: hosted through HostedInput."
  ),
  sample(
    "date-range",
    "inputs",
    "Date range selector",
    "No dedicated component yet: hosted through HostedInput."
  ),
  sample(
    "slider-range",
    "inputs",
    "Slider range",
    "No separate component needed: a two handle sliderInput() uses the same HostedInput mechanism SliderInput itself is built on."
  ),
  sample(
    "task-button",
    "inputs",
    "Task button",
    "No dedicated component yet: hosted through HostedInput."
  ),
  sample(
    "download-link",
    "inputs",
    "Download link",
    "No dedicated component yet: hosted through HostedInput."
  ),
  sample(
    "submit-button",
    "inputs",
    "Submit button",
    "A real limitation, not a bug: shiny::submitButton()'s hold-back-until-click behavior cannot work when the button is hosted. Shiny's client checks for the button once, at page load, before any hosted widget has rendered, so it never finds it and never defers sending. Values reach the server immediately instead of waiting for a click."
  ),

  sample(
    "plot-output",
    "outputs",
    "Plot",
    "Dedicated component: PlotOutput (hosts shiny::plotOutput())."
  ),
  sample(
    "value-box",
    "outputs",
    "Value box",
    "Dedicated component: ValueBox (reproduces bslib::value_box()), no input at all."
  ),
  sample(
    "datatable",
    "outputs",
    "DataTable",
    "Dedicated component: TableOutput (hosts DT::DTOutput())."
  ),
  sample(
    "table-reactable",
    "outputs",
    "Table (reactable)",
    "Dedicated component: ReactableOutput (hosts reactable::reactableOutput()). A real gotcha found here: reactable ships React itself through reactR under a dependency also named \"react\", which collided with page_react()'s own \"react\" dependency; fixed by renaming reactR's copy and loading it first."
  ),
  sample(
    "image",
    "outputs",
    "Image",
    "Dedicated component: ImageOutput (hosts shiny::imageOutput())."
  ),
  sample(
    "text-output",
    "outputs",
    "Text",
    "Dedicated component: TextOutput (hosts shiny::textOutput())."
  ),
  sample(
    "ui-output",
    "outputs",
    "UI",
    "Dedicated component: UiOutput itself, the generic escape hatch for a whole dynamic shiny::renderUI() fragment."
  ),
  sample(
    "verbatim-text",
    "outputs",
    "Verbatim text",
    "Dedicated component: VerbatimTextOutput (hosts shiny::verbatimTextOutput())."
  ),
  sample(
    "map-leaflet",
    "outputs",
    "Map (leaflet)",
    "No dedicated component: WidgetOutput, the generic htmlwidget host, given widgetClass=\"leaflet\"."
  ),
  sample(
    "plot-plotly",
    "outputs",
    "Plot (plotly)",
    "No dedicated component: WidgetOutput, the generic htmlwidget host, given widgetClass=\"plotly\"."
  ),
  sample(
    "table-plain",
    "outputs",
    "Table",
    "No dedicated component: plain shiny::tableOutput() shares uiOutput()'s own binding, so UiOutput hosts it directly."
  ),
  sample(
    "table-gt",
    "outputs",
    "Table (gt)",
    "No dedicated component: gt's output binding is plain HTML like uiOutput()'s, so UiOutput hosts it directly."
  ),

  sample(
    "notification",
    "messages",
    "Notification",
    "No bslib-react component involved at all: shiny::showNotification() renders through Shiny's own client JS, independent of the component tree."
  ),
  sample(
    "tooltip",
    "messages",
    "Tooltip",
    "Dedicated component: Tooltip (reproduces bslib::tooltip() directly, not hosted)."
  ),
  sample(
    "popover",
    "messages",
    "Popover",
    "No dedicated component: hosts the whole bslib::popover() call through UiOutput."
  ),
  sample(
    "modal",
    "messages",
    "Modal",
    "No bslib-react component involved at all: shiny::showModal() renders through Shiny's own client JS, the same discovery as Notification."
  ),
  sample(
    "progress-bar",
    "messages",
    "Progress bar",
    "No bslib-react component involved at all: shiny::withProgress()/incProgress() render through Shiny's own client JS, the same discovery as Notification and Modal."
  )
)

CATEGORIES <- list(
  list(key = "inputs", label = "Inputs"),
  list(key = "outputs", label = "Outputs"),
  list(key = "messages", label = "Display messages")
)
