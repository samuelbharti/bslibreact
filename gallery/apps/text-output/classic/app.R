library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Text"),
    sliderInput("n", "N", 1, 100, 42),
    textOutput("value")
  )
)

server <- function(input, output, session) {
  output$value <- renderText(paste("You picked", input$n))
}

shinyApp(ui, server)
