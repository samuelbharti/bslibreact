# Static name catalogs used by port_triage() (port-triage.R). Relocated
# unchanged from shinyreact-apps/tools/port/triage.R, which built these as
# local vectors at the top of the script; here they are package-level
# constants so port-triage.R's own code can stay focused on the counting
# and printing logic. Nothing here is exported.

.port_page_fns <- c(
  "page_navbar",
  "page_sidebar",
  "page_fillable",
  "page_fluid",
  "page_fixed",
  "page",
  "fluidPage",
  "fixedPage",
  "fillPage",
  "navbarPage",
  "bootstrapPage",
  "basicPage",
  "htmlTemplate",
  "page_react",
  "page_react_html"
)

.port_shiny_inputs <- c(
  "sliderInput",
  "selectInput",
  "selectizeInput",
  "varSelectInput",
  "textInput",
  "textAreaInput",
  "numericInput",
  "passwordInput",
  "checkboxInput",
  "checkboxGroupInput",
  "radioButtons",
  "dateInput",
  "dateRangeInput",
  "fileInput",
  "actionButton",
  "actionLink",
  "downloadButton",
  "downloadLink",
  "submitButton"
)

.port_bslib_inputs <- c("input_task_button", "input_dark_mode", "input_switch")

.port_other_inputs <- c(
  "pickerInput",
  "switchInput",
  "materialSwitch",
  "airDatepickerInput",
  "sliderTextInput",
  "radioGroupButtons",
  "checkboxGroupButtons",
  "prettyCheckbox",
  "prettySwitch",
  "numericRangeInput",
  "searchInput",
  "virtualSelectInput",
  "InputValidator",
  "useShinyjs"
)

.port_outputs <- c(
  "plotOutput",
  "imageOutput",
  "tableOutput",
  "dataTableOutput",
  "DTOutput",
  "textOutput",
  "verbatimTextOutput",
  "uiOutput",
  "htmlOutput",
  "reactableOutput",
  "plotlyOutput",
  "igvShinyOutput",
  "r3dmolOutput",
  "leafletOutput",
  "visNetworkOutput",
  "girafeOutput",
  "echarts4rOutput",
  "chat_ui",
  "markdown_stream_ui"
)

.port_renders <- c(
  "renderPlot",
  "renderImage",
  "renderTable",
  "renderDataTable",
  "renderDT",
  "renderText",
  "renderPrint",
  "renderUI",
  "renderReactable",
  "renderPlotly",
  "renderIgvShiny",
  "renderR3dmol",
  "renderLeaflet",
  "renderVisNetwork",
  "renderGirafe",
  "renderEcharts4r",
  "downloadHandler"
)

.port_dynamic_ui <- c(
  "renderUI",
  "uiOutput",
  "insertUI",
  "removeUI",
  "conditionalPanel",
  "insertTab",
  "removeTab",
  "showTab",
  "hideTab",
  "updateTabsetPanel",
  "updateNavbarPage",
  "nav_select",
  "nav_show",
  "nav_hide",
  "nav_insert",
  "nav_remove",
  "toggle_sidebar",
  "sidebar_toggle",
  "accordion_panel_open",
  "accordion_panel_close",
  "accordion_panel_insert",
  "accordion_panel_remove",
  "showModal",
  "removeModal",
  "showNotification",
  "show",
  "hide",
  "toggle",
  "toggleClass",
  "addClass",
  "removeClass",
  "runjs",
  "delay"
)

.port_layout <- c(
  "card",
  "card_header",
  "card_body",
  "card_footer",
  "layout_sidebar",
  "sidebar",
  "layout_columns",
  "layout_column_wrap",
  "accordion",
  "accordion_panel",
  "navset_card_tab",
  "navset_card_pill",
  "navset_card_underline",
  "navset_tab",
  "navset_pill",
  "navset_underline",
  "navset_bar",
  "navset_hidden",
  "nav_panel",
  "nav_spacer",
  "nav_item",
  "nav_menu",
  "value_box",
  "tooltip",
  "popover",
  "tabPanel",
  "tabsetPanel",
  "navlistPanel",
  "sidebarLayout",
  "sidebarPanel",
  "mainPanel",
  "fluidRow",
  "wellPanel",
  "withSpinner",
  "use_cicerone",
  "Cicerone"
)

.port_reactivity <- c(
  "reactive",
  "reactiveVal",
  "reactiveValues",
  "observe",
  "observeEvent",
  "eventReactive",
  "bindEvent",
  "bindCache",
  "debounce",
  "throttle",
  "invalidateLater",
  "ExtendedTask",
  "onSessionEnded",
  "onStop",
  "sendCustomMessage",
  "setInputValue",
  "moduleServer",
  "callModule",
  "NS"
)

# The role a package plays in a parent app, printed next to its name in
# the "Packages" section of port_triage()'s output. "" (no role) means the
# package is not one triage specifically recognizes; it is still listed,
# just with no annotation.
.port_package_role <- function(p) {
  if (
    p %in%
      c(
        "DT",
        "reactable",
        "plotly",
        "igvShiny",
        "r3dmol",
        "leaflet",
        "visNetwork",
        "ggiraph",
        "echarts4r",
        "htmlwidgets",
        "shinychat"
      )
  ) {
    return("hosted widget")
  }
  if (
    p %in%
      c(
        "shinyjs",
        "shinyvalidate",
        "shinyWidgets",
        "shinycssloaders",
        "waiter",
        "shinyFeedback",
        "shinyalert",
        "shinybusy",
        "cicerone",
        "shinyjqui"
      )
  ) {
    return("behavior, needs a plan")
  }
  if (
    p %in% c("bslib", "thematic", "sass", "bsicons", "fontawesome", "brand.yml")
  ) {
    return("theme")
  }
  if (p %in% c("mirai", "promises", "future", "crew", "coro")) {
    return("async")
  }
  ""
}
