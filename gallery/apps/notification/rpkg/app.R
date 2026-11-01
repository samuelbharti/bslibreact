library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslibreact_dep(),
  title = "Notification",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(output, "go", actionButton("go", "Show notification"))

  observeEvent(input$go, {
    showNotification("Saved successfully.", type = "message")
  })
}

shinyApp(ui, server)
