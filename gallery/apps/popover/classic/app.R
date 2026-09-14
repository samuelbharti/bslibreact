library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Popover"),
    popover(
      actionButton("pop_btn", "Options"),
      "Popover content here"
    )
  )
)

server <- function(input, output, session) {}

shinyApp(ui, server)
