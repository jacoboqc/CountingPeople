
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(dplyr)
library(tidyr)
library(httr)
library(ggplot2)

source("./server-functions.R")

refresh <- 5
begin <- as.POSIXct("2017-03-19 02:04:42 CEST")
end <- begin + refresh
mac_df <- data.frame()
mac_list <- data.frame()
sec2milis <- function(x){x*1000}

shinyServer(function(input, output, session) {

  output$time_evol <- renderPrint({
    invalidateLater(sec2milis(refresh), session)
    begin <<- begin + refresh
    end <<- end + refresh
    mac_list <<- getAllMacsByTimestamp(begin=begin, end=end)
    # woul not be necessary if filtering was done at the api
    # important: interval open on one side
    mac_list <<- mac_list[mac_list$time >= begin & mac_list$time < end,]
    cat(file=stderr(),"rows in temporal list", nrow(mac_list), "\n")
    cat(file=stderr(),"columns in temporal list", ncol(mac_list), "\n")
    cat(file=stderr(),"rows in permanent list", nrow(mac_df), "\n")
    cat(file=stderr(),"columns in permanent list", ncol(mac_df), "\n")
    names(mac_list) <<- c("MAC", "device", "ID","timestamp") # important dont move
    # solves match.names problems in rbind
    mac_df <<- rbind(mac_df, mac_list)
    cat(file=stderr(), "names of permanent and temporal dataset", 
        names(mac_df), names(mac_list), "\n")
    print(begin)
    print(end)
  })
  
  # plots amount inside the system (not fixed yet)
  output$devices_inside <- renderPlot({
    invalidateLater(sec2milis(refresh), session)
    mac_df$entering <- addEnteringStatus(mac_df)
    mac_df$inside <- addAmountInside(mac_df)
    ggplot(mac_df, aes(timestamp,inside)) + geom_line()
  })
  
  # amount of unique macs in the interval
  output$devices_seen_interval <- renderPlot({
    invalidateLater(sec2milis(refresh), session)
    mac_list$entering <- addEnteringStatus(mac_list)
    mac_list$inside <- addAmountInside(mac_list)
    ggplot(mac_list, aes(timestamp,inside)) + geom_line()
  })
  
  output$devices_seen_total <- renderPlot({
    invalidateLater(sec2milis(refresh), session)
    mac_df$entering <- addEnteringStatus(mac_df)
    mac_df$inside <- addAmountInside(mac_df)
    ggplot(mac_df, aes(timestamp,inside)) + geom_line()
    
  })
  
  

})
