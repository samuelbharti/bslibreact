library(shiny)
library(bslib)

ui <- page_fillable(
  theme = bs_theme(version = 5),
  card(
    card_header("Dark mode switch"),
    input_dark_mode(id = "dark_mode"),
    textOutput("mode")
  )
)

server <- function(input, output, session) {
  output$mode <- renderText(paste("Mode:", input$dark_mode))
}

shinyApp(ui, server)
