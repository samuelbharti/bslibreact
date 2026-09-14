library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Select"),
    selectInput("x", "Quick pick", choices = c("10", "20", "30")),
    textOutput("selected")
  )
)

server <- function(input, output, session) {
  output$selected <- renderText(paste("Selected:", input$x))
}

shinyApp(ui, server)
