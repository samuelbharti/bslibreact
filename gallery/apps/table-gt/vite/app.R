library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)
library(gt)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  title = "Table (gt)",
  theme = app_theme
)

server <- function(input, output, session) {
  output$table <- render_gt(gt(head(mtcars, 5), rownames_to_stub = TRUE))
}

shinyApp(ui, server)
