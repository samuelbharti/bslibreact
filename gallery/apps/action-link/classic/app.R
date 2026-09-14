library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Action link"),
    actionLink("go", "Clear all filters"),
    textOutput("count")
  )
)

server <- function(input, output, session) {
  output$count <- renderText(paste("Clicked", input$go, "times"))
}

shinyApp(ui, server)
