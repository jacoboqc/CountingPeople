
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
 begin <- as.POSIXct("2017-03-31 10:46:21 CEST")
# begin <- Sys.time() - 600
end <- begin + refresh
mac_df <- data.frame()
mac_list <- data.frame()
sec2milis <- function(x){x*1000}

shinyServer(function(input, output, session) {

  output$time_evol <- renderPrint({
    invalidateLater(sec2milis(refresh), session)
    cat(file=stderr(),"Before the API request", "\n")
    # mac_list <<- getAllMacsByTimestamp(begin=begin, end=end,
    #             endpoint = "http://192.168.2.102:3000/macs/interval")
    mac_list <<- getAllMacs(url = "http://192.168.2.102:3000/macs") 
    cat(file=stderr(),"After the API request", "\n")
    # woul not be necessary if filtering was done at the api
    # important: interval open on one side
    mac_list <<- mac_list[mac_list$time >= begin & mac_list$time < end,]
    cat(file=stderr(),"rows in temporal list", nrow(mac_list), "\n")
    cat(file=stderr(),"columns in temporal list", ncol(mac_list), "\n")
    cat(file=stderr(),"rows in permanent list", nrow(mac_df), "\n")
    cat(file=stderr(),"columns in permanent list", ncol(mac_df), "\n")
    names(mac_list) <<- c("MAC", "device", "ID","timestamp", "Mac_type") # important dont move
    # solves match.names problems in rbind
    mac_df <<- rbind(mac_df, mac_list)
    cat(file=stderr(), "names of permanent and temporal dataset", 
        names(mac_df), names(mac_list), "\n")
    print(begin)
    print(end)
    begin <<- begin + refresh
    end <<- end + refresh
  })
  
  # plots amount inside the system (not fixed yet)
  output$devices_inside <- renderPlot({
    invalidateLater(sec2milis(refresh), session)
    mac_df$entering <- addEnteringStatus(mac_df)
    mac_df$inside <- addAmountInside(mac_df)
    ggplot(mac_df, aes(timestamp,inside)) + geom_line()
  })
  
  #' amount of unique macs in the interval
  #' x axis: time
  #' y axis: mac count per timestamp. 
  output$macs_per_second <- renderPlot({
    invalidateLater(sec2milis(refresh), session)
    # same mac is counted as new for each timestamp 
    macs_per_second <- mac_list %>% group_by(timestamp) %>% 
      summarise(num_macs = n_distinct(MAC))
    ggplot(macs_per_second, aes(timestamp,num_macs)) + geom_col() 
       # scale_x_datetime("timestamp", labels = "%H:%M")
  })
  
  output$macs_per_second_total <- renderPlot({
    invalidateLater(sec2milis(refresh), session)
    # same mac is counted as new for each timestamp 
    macs_per_second <- mac_df %>% group_by(timestamp) %>% 
      summarise(num_macs = n_distinct(MAC))
    ggplot(macs_per_second, aes(timestamp,num_macs)) + geom_col() 
       # scale_x_datetime("timestamp", labels = date_format("%M:%S"))
  })
  # 
  # output$mac_observations <- renderPlot({
  #   
  # })
  # 
  # output$time_per_mac <- renderPlot({
  #   ## straw
  #   getMinOrMax <- function(mac, data, min_or_max, mac_col, time_col){
  #     min_or_max(data[data[mac_col]==mac, time_col])
  #   }
  #   #mapply(f, unlist(lista_macs), MoreArgs=list(data=macs, mac_col="mac", min_or_max=min, time_col="time"))
  #   ##
  #   x <- runif(n_distinct(mac_df$MAC), min = 0, max = as.numeric(end-begin)/15)
  #   plot(x)
  #   
  # })
  # 
})

