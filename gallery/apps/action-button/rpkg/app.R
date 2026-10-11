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
  # The hosted button has no value until it binds, so wait for it instead of
  # showing "Clicked times" with no number.
  output$count <- renderText({
    req(!is.null(input$go))
    paste("Clicked", input$go, "times")
  })
}

shinyApp(ui, server)
