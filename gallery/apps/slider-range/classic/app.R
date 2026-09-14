library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Slider range"),
    sliderInput("range", "Range", min = 0, max = 100, value = c(25, 75)),
    textOutput("chosen")
  )
)

server <- function(input, output, session) {
  output$chosen <- renderText(paste(
    "From",
    input$range[1],
    "to",
    input$range[2]
  ))
}

shinyApp(ui, server)
