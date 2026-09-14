library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslib_react_dep(),
  title = "Plot",
  theme = app_theme
)

server <- function(input, output, session) {
  output$plot <- renderPlot({
    plot(pressure, col = "#447099", pch = 19)
  })
}

shinyApp(ui, server)
