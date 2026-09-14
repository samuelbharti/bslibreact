library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Action button"),
    actionButton("go", "Click me"),
    textOutput("count")
  )
)

server <- function(input, output, session) {
  output$count <- renderText(paste("Clicked", input$go, "times"))
}

shinyApp(ui, server)
