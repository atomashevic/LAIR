
install.packages("shinyjs", dependencies = TRUE)
install.packages("shinydashboard")
install.packages("devtools")

devtools::install_local("taipan_0.1.2.tar.gz", force = TRUE)

library(taipan)
library(shiny)
library(shinydashboard)

files <- list.files(path = getwd(), pattern = ".jpg", recursive = TRUE)

images <- sample(files, 50)

ids <- gsub("content/", "", images)
ids <- gsub("/frame_", "-", ids)
ids <- gsub(".jpg", "", ids)

data <- data.frame(id = ids, image = images, text = rep("test", length(ids)))

questions <- taipanQuestions(
  scene = div(radioButtons("face", label = "Can you see a face of a politician on this image?", choices = c("Yes", "No"), selected = "No"),
                      sliderInput("neutrality", label = "How neutral (unemotional) is the facial expression? ",
                                  min = 0, max = 10, value = 10, step = 0.5, ticks = FALSE),
                     sliderInput("anger", label = "Intensity of Anger",
                         min = 0, max = 10, value = 0, step = 0.5, ticks = FALSE),
               sliderInput("fear", label = "Intensity of Fear",
                           min = 0, max = 10, value = 0, step = 0.5, ticks = FALSE),
               sliderInput("sadness", label = "Intensity of Sadness", 
                          min = 0, max = 10, value = 0, step = 0.5, ticks = FALSE),
               sliderInput("happiness", label = "Intensity of Happiness",
                           min = 0, max = 10, value = 0, step = 0.5, ticks = FALSE),
               sliderInput("surprise", label = "Intensity of Hope",
                           min = 0, max = 10, value = 0, step = 0.5, ticks = FALSE),
               sliderInput("disgust", label = "Intensity of Pride", 
                           min = 0, max = 10, value = 0, step = 0.5, ticks = FALSE))
                ,selection = div()
)

buildTaipan(
    questions = questions,
    images = data$image,
    # appdir = file.path(tempdir(), "taipan"), overwrite = FALSE
    appdir = file.path("app/"), overwrite = FALSE
)
