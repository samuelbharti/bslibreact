library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslibreact_dep(),
  title = "Dark mode switch",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(output, "dark_mode", input_dark_mode(id = "dark_mode"))
  output$mode <- renderText(paste("Mode:", req(input$dark_mode)))
}

shinyApp(ui, server)
