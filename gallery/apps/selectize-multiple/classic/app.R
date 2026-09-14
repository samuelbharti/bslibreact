library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Selectize (multiple)"),
    selectizeInput(
      "genes",
      "Genes",
      choices = c("A", "B", "C"),
      selected = "A",
      multiple = TRUE
    ),
    textOutput("selected")
  )
)

server <- function(input, output, session) {
  output$selected <- renderText(paste(
    "Selected:",
    paste(input$genes, collapse = ", ")
  ))
}

shinyApp(ui, server)
