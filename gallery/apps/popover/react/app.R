library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslib_react_dep(),
  title = "Popover",
  theme = app_theme
)

server <- function(input, output, session) {
  output$pop <- renderUI({
    popover(
      actionButton("pop_btn", "Options"),
      "Popover content here"
    )
  })
}

shinyApp(ui, server)
