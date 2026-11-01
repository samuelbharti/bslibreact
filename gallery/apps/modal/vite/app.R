library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  title = "Modal",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(output, "go", actionButton("go", "Show modal"))
  observeEvent(input$go, {
    showModal(modalDialog(
      title = "Confirm",
      "Are you sure you want to continue?",
      easyClose = TRUE
    ))
  })
}

shinyApp(ui, server)
