library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslib_react_dep(),
  title = "Action button",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(output, "go", actionButton("go", "Click me"))
  output$count <- renderText(paste("Clicked", input$go, "times"))
}

shinyApp(ui, server)
