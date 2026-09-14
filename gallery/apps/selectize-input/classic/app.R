library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Selectize"),
    selectizeInput(
      "gene",
      "Search for a gene",
      choices = NULL,
      options = list(placeholder = "Symbol or Ensembl id", maxOptions = 50)
    ),
    textOutput("selected")
  )
)

server <- function(input, output, session) {
  updateSelectizeInput(
    session,
    "gene",
    choices = c("BRCA1", "TP53", "EGFR"),
    server = TRUE
  )
  output$selected <- renderText(paste("Selected:", input$gene))
}

shinyApp(ui, server)
