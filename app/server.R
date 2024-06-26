library(shiny)
library(ggplot2)
library(purrr)
library(png)
library(shinyjs)

getInputID <- function(input){
  if(!inherits(input, "shiny.tag")){
    return()
  }
  c(
    if(!is.null(input$attribs$id)){list(list(id=input$attribs$id, type = input$name))}else{NULL},
    do.call("c", map(input$children, getInputID))
  )
}

shinyServer(
  function(input, output, session) {
    questions <- readRDS("data/questions.Rds")
    image_list <- list.files("www/app_images", full.names = TRUE)

    v <- reactiveValues(
      imageNum = 1,
      current_sel = NULL,
      editing = FALSE,
      responses = list()
    )

    current_img <- reactive({
      image_list[v$imageNum]
    })
    current_sel <- reactive({
      v$current_sel
    })
    current_area <- reactive({
      if(!is.null(input$img_brush)){
        size <- as.numeric(input$img_brush$range[c("right", "bottom")]) + 1
        scale <- size / input$taipan_img_dim
        brush <- input$img_brush[c("xmin", "xmax", "ymin", "ymax")]
        map2(brush, rep(scale, each = 2), ~ .x / .y)
      }
      else if(!is.null(current_sel())){
        sel_val <- v$responses[[basename(current_img())]][["selection"]][[current_sel()]]
        list(
          xmin = sel_val$pos$xmin,
          xmax = sel_val$pos$xmax,
          ymin = sel_val$pos$ymin,
          ymax = sel_val$pos$ymax
        )
      }
      else{
        NULL
      }
    })

    output$out_img_overlay <- renderImage({
      session$sendCustomMessage("get_dim","taipan_current_img")

      if(!isTruthy(input$taipan_img_dim)){
        invalidateLater(500)
        req(FALSE)
      }

      out_width <- input$taipan_img_dim[1]
      out_height <- input$taipan_img_dim[2]

      xlim <- c(0, out_width)
      ylim <- c(-out_height, 0)

      selection_data <- do.call("rbind",
                                c(list(data.frame(xmin=numeric(), xmax=numeric(), ymin=numeric(), ymax=numeric())),
                                  map(v$responses[[basename(current_img())]][["selection"]],
                                      function(x) as.data.frame(x$pos))
                                )
      )
      selection_data <- transform(selection_data, current = seq_len(NROW(selection_data)) %in% current_sel())
      p <- ggplot(selection_data, aes(xmin=xmin, xmax=xmax, ymin=-ymax, ymax=-ymin, colour = current)) +
        scale_x_continuous(limits = xlim, expand=c(0,0)) +
        scale_y_continuous(limits = ylim, expand=c(0,0)) +
        geom_rect(fill="transparent") +
        theme_void() +
        theme(
          panel.background = element_rect(fill = "transparent") # bg of the panel
          , plot.background = element_rect(fill = "transparent", colour = NA) # bg of the plot
          , legend.background = element_rect(fill = "transparent") # get rid of legend bg
          , legend.box.background = element_rect(fill = "transparent") # get rid of legend panel bg
        ) +
        scale_colour_manual(values = c("TRUE" = "#00A65A", "FALSE" = "white")) +
        guides(colour = "none")
      ggsave(overlay_img <- tempfile(), p, png, width = out_width,
             height = out_height, limitsize = FALSE, bg = "transparent")
      list(src = overlay_img)
    })

    output$out_img <- renderImage({
      list(src = current_img(), id = "taipan_current_img")
    }, deleteFile = FALSE)

    output$out_img_info <- renderText({
      sprintf("Image: %s (%i/%i)",
              basename(current_img()),
              v$imageNum,
              length(image_list))
    })

    sceneInputs <- getInputID(questions$scene)
    selectionInputs <- getInputID(questions$selection)

    scene_vals <- reactive({
      vals <- map(sceneInputs, function(id){input[[id$id]]})
      names(vals) <- map_chr(sceneInputs, "id")
      vals
    })

    selection_vals <- reactive({
      vals <- map(selectionInputs, function(id){input[[id$id]]})
      names(vals) <- map_chr(selectionInputs, "id")
      vals
    })

    output$ui_instructions <- renderUI({
      # These instructions can be used as a welcome section to explain your app
      box(
        title = "Instructions",
            tags$style(HTML("
            .instructions {
            font-size: 20px;
            }
        ")),
        h3("Welcome to the LAIR (Labeling & Annotating in R) Exercise!"),
        p("On the right side of the screen, you have questions regarding the image displayed on the left."), br(),
        p("These answers can be saved by clicking the", strong("Save Image button"), "or continuing to the", strong(" Next image.")), br(),
        p("First answer the question regarding whether you can clearly see,", strong("a face of a politician"), "in the image."), br(),
        p(strong("If your answer is Yes,"), "then you can proceed to questions regarding the emotions. Otherwise, you can proceed to the Next image."), br(),
        p("If you need help with the definition of emotions you can click the", strong("Help! button"), "to open a new tab with the definitions."),
        status = "warning",
        solidHeader = TRUE,
        collapsible = TRUE,
        width = 12)
    })

    output$ui_questions <- renderUI({
      if(!is.null(current_sel())){
        box(
          title = "Selection",
          questions$selection,
          width = 12,
          status = "success",
          solidHeader = TRUE,
          collapsible = TRUE
        )
      }
      else{
        box(
          title = "Scene",
          questions$scene,
          width = 12,
          status = "info",
          solidHeader = TRUE,
          collapsible = TRUE
        )
      }
    })

    output$ui_help <- renderUI({
      actionLink(
        "btn_help",
        box(
          "Help!",
          width = 2,
          background = "red", offset=0
        )
      )
    })

    output$ui_save <- renderUI({
      if(!is.null(current_sel())){
        actionLink(
          "btn_saveSelection",
          box(
            "Save Selection",
            width = 2,
            background = "blue", offset=0
          )
        )
      } else {
        actionLink(
          "btn_saveImage",
          box(
            "Save Image",
            width = 2,
            background = "blue", offset=0
          )
        )
      }
    })

    output$ui_btn_next <- renderUI({
      if (v$imageNum != length(image_list)) {
        actionLink(
          "btn_next",
          box(
            "Next Image",
            width = 2,
            background = "green",
            offset = 0
          )
        )
      }
      else {
        column(3)
      }
    })

    output$ui_btn_prev <- renderUI({
      if (v$imageNum != 1) {
        actionLink(
          "btn_prev",
          box(
            "Previous Image",
            width = 3,
            background = "green"
          )
        )
      }
      else {
        column(3)
      }
    })

    observeEvent(v$editing, {
      output$ui_deleteSelection <- renderUI({
        if(!is.null(current_sel()) & v$editing){
          actionLink(
            "btn_deleteSelection",
            box(
              "Delete Selection",
              width = 3,
              background = "red", offset=1
            )
          )
        } else {
          column(3)
        }
      })})

    observeEvent(input$img_brush, {
      if(is.null(input$img_brush)){
        v$current_sel <- NULL
      }
      else{
        v$current_sel <- length(v$responses[[basename(current_img())]][["selection"]]) + 1
      }
    })

    # Additional test for removing brush
    observeEvent(input$img_click, {
      if(is.null(input$img_brush)){
        v$current_sel <- NULL
      }
    })

    observeEvent(input$img_dblclick, {
      size <- as.numeric(input$img_dblclick$range[c("right", "bottom")]) + 1
      scale <- size / input$taipan_img_dim
      xpos <- input$img_dblclick$x/scale[1]
      ypos <- input$img_dblclick$y/scale[2]
      # match in reverse order if overlaid
      match <- map_lgl(v$responses[[basename(current_img())]][["selection"]],
                       function(sel){
                         (xpos >= sel$pos$xmin) &&
                           (xpos <= sel$pos$xmax) &&
                           (ypos >= sel$pos$ymin) &&
                           (ypos <= sel$pos$ymax)
                       }
      )
      sel_match <- which(match)

      if(length(sel_match) > 0){
        if(any(rem <- sel_match < current_sel())){
          sel_match <- sel_match[rem]
        }

        v$current_sel <- sel_match <- max(sel_match)
        v$editing <- TRUE

        # Update selection inputs
        map(selectionInputs,
            function(io){
              val <- v$responses[[basename(current_img())]][["selection"]][[sel_match]][["inputs"]][[io$id]]
              session$sendInputMessage(
                io$id,
                list(
                  value = val,
                  selected = val
                )
              )
            }
        )
      }
      else{
        showNotification(h3("Could not find matching selection, please select a unique area of a square."),
                         type = "error")
      }
    })

    # Update the scene values when images change
    observeEvent(c(current_img(),current_sel()), {
      if(is.null(current_sel())){
        map(sceneInputs,
            function(io){
              # Update scene inputs
              val <- v$responses[[basename(current_img())]][["scene"]][[io$id]]
              if(!is.null(val)){
                session$sendInputMessage(
                  io$id,
                  list(
                    value = val,
                    selected = val
                  )
                )
              }
            }
        )
      }
    })

    observeEvent(scene_vals(), {
      v$responses[[basename(current_img())]][["scene"]] <- scene_vals()
    })

    observeEvent(input$btn_prev, {
      v$responses[[basename(current_img())]][["scene"]] <- scene_vals()
      session$resetBrush("img_brush")
      v$current_sel <- NULL
      v$imageNum <- pmax(1, v$imageNum - 1)
    })

    observeEvent(input$btn_next, {
      v$responses[[basename(current_img())]][["scene"]] <- scene_vals()
      session$resetBrush("img_brush")
      v$current_sel <- NULL
      v$imageNum <- pmin(length(image_list), v$imageNum + 1)
      v$editing <- FALSE
    })

    observeEvent(input$btn_saveSelection, {
      v$responses[[basename(current_img())]][["selection"]][[current_sel()]] <-
        list(pos = current_area(),
             inputs = selection_vals()
        )
      session$resetBrush("img_brush")
      v$current_sel <- NULL
      v$editing <- FALSE
    })

    observeEvent(input$btn_help, {
      browseURL("https://emotiontypology.com/")
    })

    observeEvent(input$btn_saveImage, {
      showNotification(h3("Scene information has been saved."), type = "default")
    })

    observeEvent(input$btn_deleteSelection, {
      v$responses[[basename(current_img())]][["selection"]][[current_sel()]] <- NULL
      v$current_sel <- NULL
      v$editing <- FALSE
    })

    output$btn_export <- downloadHandler(
      filename = function() {
        paste('taipan-export-', Sys.Date(), '.csv', sep='')
      },
      content = function(con){
        v$responses[[basename(current_img())]][["scene"]] <- scene_vals()
        out <- suppressWarnings( # hide coercion warnings
          v$responses %>%
            imap_dfr(
              function(img, image_name){
                scene_vals <- img$scene %>%
                  map(paste0, collapse = ", ")
                selection_vals <- img$selection %>%
                  map_dfr(function(sel_val){
                    c(sel_val$pos,
                      sel_val$inputs %>%
                        map(paste0, collapse = ", ")
                    ) %>%
                      as.data.frame
                  })
                as.data.frame(c(image_name = image_name, scene_vals, selection_vals))
              }
            )
        )
        write.csv(out, con, row.names = FALSE)
      }
    )
  }
  )
