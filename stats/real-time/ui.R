
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
    column(width=6,  titlePanel("Macs per second (interval)")),
    column(width=6,  titlePanel("Macs per second"))
  ),
  fluidRow(
    column(width=6,  plotOutput("macs_per_second")),
    column(width=6,  plotOutput("macs_per_second_total"))
  ),
  fluidRow(
    column(width=6,  titlePanel("Time per mac")),
    column(width=6,  titlePanel("Time between burst"))
    #column(width=6,  titlePanel("Observations per mac"))
  ),
  fluidRow(
    column(width=6,  plotOutput("time_per_mac")),
    column(width=6,  plotOutput("macs_per_second_total"))
  )
))
