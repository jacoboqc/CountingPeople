
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)

shinyUI(fluidPage(

  # Application title
  titlePanel("Macs evolution"),
  fluidRow(
  textOutput("time_evol")
  ),
  fluidRow(
    column(width=6,  titlePanel("Devices in the interval")),
    column(width=6,  titlePanel("Devices since beginning"))
  ),
  fluidRow(
    column(width=6,  plotOutput("devices_seen_interval")),
    column(width=6,  plotOutput("devices_seen_total"))
  )
))
