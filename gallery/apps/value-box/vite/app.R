library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslib_react_dep(),
  title = "Value box",
  theme = app_theme
)

server <- function(input, output, session) {
  output$ngenes <- renderText("248")
}

shinyApp(ui, server)
