library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Tooltip"),
    tooltip(
      icon("circle-info"),
      "Extra detail on hover"
    )
  )
)

server <- function(input, output, session) {}

shinyApp(ui, server)
