library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Checkbox group"),
    checkboxGroupInput(
      "opts",
      "Choose",
      choices = c("One" = "one", "Two" = "two")
    ),
    textOutput("selected")
  )
)

server <- function(input, output, session) {
  output$selected <- renderText(paste(
    "Selected:",
    paste(input$opts, collapse = ", ")
  ))
}

shinyApp(ui, server)
