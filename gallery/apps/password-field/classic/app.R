library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Password field"),
    passwordInput("key", "API key", placeholder = "Paste your key"),
    textOutput("status")
  )
)

server <- function(input, output, session) {
  output$status <- renderText(
    if (nzchar(input$key)) "Key entered" else "No key yet"
  )
}

shinyApp(ui, server)
