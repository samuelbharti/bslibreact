library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)
library(DT)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslib_react_dep(),
  title = "DataTable",
  theme = app_theme
)

server <- function(input, output, session) {
  output$table <- renderDT(mtcars, options = list(pageLength = 5))
}

shinyApp(ui, server)
