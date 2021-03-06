

# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com

library(shiny)
library(shinythemes)

shinyUI(navbarPage(
  "CountingPeople",
  tabPanel("Real-time", fluidPage(
    # Sidebar with the input options
    sidebarPanel(
      tags$h3("Options"),
      
      sliderInput(
        "s",
        "Refresh:",
        min = 1,
        max = 60,
        value = 5,
        step = 5
      ),
      
      sliderInput(
        "n",
        "Elements in screen",
        min = 1,
        max = 10,
        value = 5,
        step = 1
      )
    ),
    
    mainPanel(tabsetPanel(
      # instant
      tabPanel("Now", fluidPage(
        fluidRow(column(width = 12, textOutput("time_evol"))),
        h3(textOutput("new_devices_interval")),
        fluidRow(column(width = 6,  titlePanel("Mac count per second")),
                 column(width = 6,  titlePanel("New macs per second"))),
        fluidRow(column(width = 6,  plotOutput("macs_per_second")),
                 column(width = 6,  plotOutput("new_macs_per_second"))),
        fluidRow(column(width = 6,  titlePanel("Time between burst"))),
        fluidRow(column(width = 6,  plotOutput("time_between_bursts")))
      )),
      
      # acumulated
      tabPanel("Acumulated", fluidPage(fluidRow(
        column(width = 6,  titlePanel("Macs per second"))
      ),
      fluidRow(
        column(width = 6,  plotOutput("macs_per_second_total"))
      )))
    ))
  )),
  
  # static tab (generates pdf and upload it)
  tabPanel("Static",
           fluidPage(
             includeScript("background.js"), 
             actionButton("static_annalyse", "Generate a static annalyse"),
              div(id="content_iframe")
             )
  ),
  theme = shinytheme("cerulean")
  
))
