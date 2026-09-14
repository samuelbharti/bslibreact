library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Verbatim text"),
    sliderInput("n", "N", 1, 100, 42),
    verbatimTextOutput("summary")
  )
)

server <- function(input, output, session) {
  output$summary <- renderPrint(summary(rnorm(input$n)))
}

shinyApp(ui, server)
