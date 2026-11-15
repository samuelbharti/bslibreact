library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslibreact_dep(),
  title = "Tooltip",
  theme = app_theme
)

server <- function(input, output, session) {}

shinyApp(ui, server)
