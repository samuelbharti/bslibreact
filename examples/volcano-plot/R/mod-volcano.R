# Volcano plot Shiny module.
#
# All arguments after `id` are reactives, so the module composes cleanly:
# pass app-level inputs in, get the prepared data back out. Kept as a real
# module (rather than inlined into app.R's server) because this is the
# shape a larger app reuses it in; a smaller example could inline it.

volcano_ui <- function(id) {
  ns <- shiny::NS(id)
  # click makes points selectable: the server maps the click to the
  # nearest gene. Not read by this example's own UI, but kept so the
  # module's shape matches what a larger app would build on.
  shiny::plotOutput(ns("plot"), height = "560px", click = ns("click"))
}

# de_results, lfc_threshold, p_threshold, p_col, label_top_n: reactives.
# Returns a list of reactives:
#   $data    -- the volcano_data() data frame (for summaries / value boxes)
#   $clicked -- the gene under the most recent point click (NULL until one)
volcano_server <- function(
  id,
  de_results,
  lfc_threshold,
  p_threshold,
  p_col,
  label_top_n,
  xlab = shiny::reactive(expression(log[2] ~ fold ~ change)),
  highlight = shiny::reactive(character(0))
) {
  shiny::moduleServer(id, function(input, output, session) {
    vdata <- shiny::reactive({
      volcano_data(
        de_results(),
        lfc_threshold = lfc_threshold(),
        p_threshold = p_threshold(),
        p_col = p_col(),
        label_top_n = label_top_n()
      )
    })

    output$plot <- shiny::renderPlot(
      {
        plot_volcano(
          vdata(),
          lfc_threshold(),
          p_threshold(),
          xlab = xlab(),
          highlight = highlight()
        )
      },
      res = 96
    )

    clicked <- shiny::reactiveVal(NULL)
    shiny::observeEvent(input$click, {
      np <- shiny::nearPoints(
        vdata(),
        input$click,
        xvar = "logFC",
        yvar = "neg_log10_p",
        maxpoints = 1
      )
      if (nrow(np) > 0) {
        clicked(np$gene[1])
      }
    })

    list(data = vdata, clicked = clicked)
  })
}
