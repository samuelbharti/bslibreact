library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Submit button"),
    sliderInput("n", "N", 1, 100, 42),
    submitButton("Apply"),
    textOutput("value")
  )
)

server <- function(input, output, session) {
  output$value <- renderText(paste("Applied N =", input$n))
}

shinyApp(ui, server)
