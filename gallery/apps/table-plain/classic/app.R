library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Table"),
    tableOutput("table")
  )
)

server <- function(input, output, session) {
  output$table <- renderTable(head(mtcars, 5))
}

shinyApp(ui, server)
