library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslib_react_dep(),
  title = "Download link",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(output, "dl", downloadLink("dl", "Download the data"))
  output$dl <- downloadHandler(
    filename = "data.csv",
    content = function(file) write.csv(mtcars, file)
  )
}

shinyApp(ui, server)
