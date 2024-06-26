library(shiny)
library(shinydashboard)

shinyUI(
  dashboardPage(
    dashboardHeader(
      title = "LAIR",
      tags$li(class = "dropdown", downloadLink("btn_export", span(icon("download"), " Export Responses"))),
      tags$li(class = "dropdown", a(href="https://github.com/atomashevic/LAIR-UVA", target="_blank", span(icon("github"), " GitHub")))
    ),
    dashboardSidebar(
      disable = TRUE
    ),
    dashboardBody(
      includeScript("www/img_size.js"),
      includeCSS("www/taipan.css"),
      column(6,
             box(
        title = textOutput("out_img_info"),
        div(class = "taipan_image_div",
            imageOutput("out_img_overlay",
                        click = clickOpts(id = "img_click"),
                        dblclick = dblclickOpts(id = "img_dblclick"),
                        brush = brushOpts(id = "img_brush", stroke = "#00A65A", fill = "transparent", opacity = 1),
                        inline=TRUE),
            imageOutput("out_img",
                        inline = TRUE)
        ),
        width = 12,
        status = "primary",
        collapsible = TRUE
      ),
      uiOutput("ui_instructions")),

      column(6,
             uiOutput("ui_questions"),
             uiOutput("ui_btn_prev"),
             uiOutput("ui_deleteSelection"),
             uiOutput("ui_save"),
             uiOutput("ui_help"),
             uiOutput("ui_btn_next")
      )
    )
  )
)
