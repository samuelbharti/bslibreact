library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  title = "Checkbox group",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(
    output,
    "opts",
    checkboxGroupInput(
      "opts",
      "Choose",
      choices = c("One" = "one", "Two" = "two")
    )
  )
  output$selected <- renderText(paste(
    "Selected:",
    paste(input$opts, collapse = ", ")
  ))
}

shinyApp(ui, server)
