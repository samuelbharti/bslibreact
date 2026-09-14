library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Numeric input"),
    numericInput(
      "pc",
      "Loadings for PC",
      value = 1,
      min = 1,
      max = 10,
      step = 1
    ),
    textOutput("value")
  )
)

server <- function(input, output, session) {
  output$value <- renderText(paste("PC:", input$pc))
}

shinyApp(ui, server)
