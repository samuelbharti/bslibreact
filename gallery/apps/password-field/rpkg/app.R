library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslibreact_dep(),
  title = "Password field",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(
    output,
    "key",
    passwordInput("key", "API key", placeholder = "Paste your key")
  )
  output$status <- renderText({
    req(!is.null(input$key))
    if (nzchar(input$key)) "Key entered" else "No key yet"
  })
}

shinyApp(ui, server)
