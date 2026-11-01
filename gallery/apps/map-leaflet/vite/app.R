library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)
library(leaflet)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslib_react_dep(),
  title = "Map (leaflet)",
  theme = app_theme
)

server <- function(input, output, session) {
  output$map <- renderLeaflet({
    leaflet() |> addTiles() |> setView(lng = -0.09, lat = 51.505, zoom = 12)
  })
}

shinyApp(ui, server)
