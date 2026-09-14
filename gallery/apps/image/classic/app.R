library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Image"),
    imageOutput("img", height = "300px")
  )
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
