library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslib_react_dep(),
  title = "Submit button",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(output, "n", sliderInput("n", "N", 1, 100, 42))
  host_input(output, "apply", submitButton("Apply"))
  # The hosted slider has no value until it binds, so wait for it instead
  # of showing "Applied N =" with no number.
  output$value <- renderText({
    req(!is.null(input$n))
    paste("Applied N =", input$n)
  })
}

shinyApp(ui, server)
