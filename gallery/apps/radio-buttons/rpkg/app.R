library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslibreact_dep(),
  title = "Radio buttons",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(
    output,
    "values",
    radioButtons(
      "values",
      "Values",
      choices = c("Row z-score" = "row", "Expression" = "none")
    )
  )
  output$selected <- renderText(paste("Selected:", req(input$values)))
}

shinyApp(ui, server)
