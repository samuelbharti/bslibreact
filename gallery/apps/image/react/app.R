library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslib_react_dep(),
  title = "Image",
  theme = app_theme
)

server <- function(input, output, session) {
  output$img <- renderImage(
    {
      path <- tempfile(fileext = ".png")
      png(path, width = 400, height = 300)
      plot(pressure, col = "#447099", pch = 19)
      dev.off()
      list(src = path, contentType = "image/png", width = 400, height = 300)
    },
    deleteFile = TRUE
  )
}

shinyApp(ui, server)
