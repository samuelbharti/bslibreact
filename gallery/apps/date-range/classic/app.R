library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Date range selector"),
    dateRangeInput("dates", "Date range"),
    textOutput("chosen")
  )
)

server <- function(input, output, session) {
  output$chosen <- renderText(paste(
    "From",
    input$dates[1],
    "to",
    input$dates[2]
  ))
}

shinyApp(ui, server)
