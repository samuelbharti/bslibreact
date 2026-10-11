# Volcano plot, a small real analysis app built with bslib-react.
#
# The React client (src/, built to www/ui.js) owns the page. This file
# holds only reactive computation and the ggplot2 rendering that R does
# better than a client-side chart library would for this kind of plot.
library(shiny)
library(bslib)
library(shinyreact)
library(ggplot2)
library(ggrepel)

for (f in list.files("R", pattern = "[.][Rr]$", full.names = TRUE)) {
  source(f)
}
for (f in list.files("R/_shared", pattern = "[.][Rr]$", full.names = TRUE)) {
  source(f)
}

app_theme <- bs_theme(version = 5, brand = TRUE)

de_results <- utils::read.csv("data/de_results.csv", stringsAsFactors = FALSE)

ui <- page_react(
  title = "Volcano plot",
  theme = app_theme,
  bslibreact::page_deps(app_theme)
)

server <- function(input, output, session) {
  # Every hosted input is renderUI()-wrapped and hosted through bslib-react's
  # HostedInput components (see docs/build.md, "Hosting a widget").
  bslibreact::host_input(
    output,
    "lfc",
    sliderInput(
      "lfc",
      "|log2 fold change| threshold",
      min = 0,
      max = 5,
      value = 1,
      step = 0.1
    )
  )
  bslibreact::host_input(
    output,
    "p",
    sliderInput(
      "p",
      "Significance threshold",
      min = 0.001,
      max = 0.1,
      value = 0.05,
      step = 0.001
    )
  )
  bslibreact::host_input(
    output,
    "pcol",
    radioButtons(
      "pcol",
      "Significance metric",
      choices = c("Adjusted p" = "padj", "Raw p" = "pvalue")
    )
  )
  bslibreact::host_input(
    output,
    "dolabel",
    checkboxInput("dolabel", "Label top genes", value = TRUE)
  )
  bslibreact::host_input(
    output,
    "topn",
    sliderInput("topn", "Max labels", min = 0, max = 30, value = 10, step = 1)
  )

  # Hosted inputs have no value until the client has bound them, so each
  # one waits with req(). An unchecked box is FALSE, which req() would also
  # stop on, so the checkbox is tested with is.null().
  vol <- volcano_server(
    "volcano",
    de_results = reactive(de_results),
    lfc_threshold = reactive(req(input$lfc)),
    p_threshold = reactive(req(input$p)),
    p_col = reactive(req(input$pcol)),
    label_top_n = reactive({
      req(!is.null(input$dolabel), !is.null(input$topn))
      if (isTRUE(input$dolabel)) input$topn else 0L
    })
  )

  counts <- reactive(volcano_status_counts(vol$data()))
  output$n_up <- renderText(as.character(counts()[["Up"]]))
  output$n_down <- renderText(as.character(counts()[["Down"]]))
  output$n_ns <- renderText(as.character(counts()[["NS"]]))
}

shinyApp(ui = ui, server = server)
