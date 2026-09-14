library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Date selector"),
    dateInput("date1", "Date"),
    textOutput("chosen")
  )
)

server <- function(input, output, session) {
  output$chosen <- renderText(paste("Chosen:", input$date1))
}

shinyApp(ui, server)
