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
      png(path, width = 500, height = 375, res = 100)
      par(cex.main = 1.4, cex.lab = 1.3, cex.axis = 1.15, mar = c(5, 5, 2, 1))
      plot(
        pressure,
        col = "#447099",
        pch = 19,
        cex = 1.3,
        xlab = "Temperature",
        ylab = "Pressure"
      )
      dev.off()
      list(src = path, contentType = "image/png", width = 500, height = 375)
    },
    deleteFile = TRUE
  )
}

shinyApp(ui, server)
