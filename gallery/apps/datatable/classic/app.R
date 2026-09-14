library(shiny)
library(bslib)
library(DT)

ui <- page_fillable(
  card(
    card_header("DataTable"),
    DTOutput("table")
  )
)

server <- function(input, output, session) {
  output$table <- renderDT(mtcars, options = list(pageLength = 5))
}

shinyApp(ui, server)
