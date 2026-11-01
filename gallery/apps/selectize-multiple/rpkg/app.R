library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslibreact_dep(),
  title = "Selectize (multiple)",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(
    output,
    "genes",
    selectizeInput(
      "genes",
      "Genes",
      choices = c("A", "B", "C"),
      selected = "A",
      multiple = TRUE
    )
  )
  output$selected <- renderText(paste(
    "Selected:",
    paste(input$genes, collapse = ", ")
  ))
}

shinyApp(ui, server)
