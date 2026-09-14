library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslib_react_dep(),
  title = "Task button",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(output, "run", input_task_button("run", "Run analysis"))
  output$status <- renderText(paste("Ran", input$run, "times"))
}

shinyApp(ui, server)
