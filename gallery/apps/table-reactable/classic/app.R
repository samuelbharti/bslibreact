library(shiny)
library(bslib)
library(reactable)

ui <- page_fillable(
  card(
    card_header("Table (reactable)"),
    reactableOutput("table")
  )
)

server <- function(input, output, session) {
  output$table <- renderReactable(reactable(mtcars))
}

shinyApp(ui, server)
