library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  title = "Table",
  theme = app_theme
)

server <- function(input, output, session) {
  output$table <- renderTable(head(mtcars, 5))
}

shinyApp(ui, server)
