library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslibreact_dep(),
  title = "Progress bar",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(output, "go", actionButton("go", "Start task"))
  observeEvent(input$go, {
    withProgress(message = "Working", value = 0, {
      for (i in 1:10) {
        incProgress(1 / 10)
        Sys.sleep(0.1)
      }
    })
  })
}

shinyApp(ui, server)
