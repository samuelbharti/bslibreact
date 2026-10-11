library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  title = "Task button",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(output, "run", input_task_button("run", "Run analysis"))
  # The hosted button has no value until it binds, so wait for it instead of
  # showing "Ran times" with no number.
  output$status <- renderText({
    req(!is.null(input$run))
    paste("Ran", input$run, "times")
  })
}

shinyApp(ui, server)
