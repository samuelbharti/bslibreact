library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslibreact_dep(),
  title = "Selectize",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(
    output,
    "gene",
    selectizeInput(
      "gene",
      "Search for a gene",
      choices = NULL,
      options = list(placeholder = "Symbol or Ensembl id", maxOptions = 50)
    )
  )
  updateSelectizeInput(
    session,
    "gene",
    choices = c("BRCA1", "TP53", "EGFR"),
    server = TRUE
  )
  output$selected <- renderText(paste("Selected:", req(input$gene)))
}

shinyApp(ui, server)
