library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslibreact_dep(),
  title = "Checkbox",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(
    output,
    "cluster",
    checkboxInput("cluster", "Cluster genes", value = TRUE)
  )
  output$status <- renderText({
    req(!is.null(input$cluster))
    if (input$cluster) "Clustering on" else "Clustering off"
  })
}

shinyApp(ui, server)
