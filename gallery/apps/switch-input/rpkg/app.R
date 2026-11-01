library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslibreact_dep(),
  title = "Switch",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(
    output,
    "enabled",
    input_switch("enabled", "Enable feature", value = FALSE)
  )

  output$status <- renderText({
    req(!is.null(input$enabled))
    if (isTRUE(input$enabled)) "Feature is on" else "Feature is off"
  })
}

shinyApp(ui, server)
