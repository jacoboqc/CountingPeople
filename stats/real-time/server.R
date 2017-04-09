
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
library(scales)
library(grid)
library(RColorBrewer)
library(rmarkdown)

source("./server-functions.R")
source("../static-analysis.R")

refresh <- 5
# begin <- Sys.time() - 1200
begin <- as.POSIXct("2017-03-06 17:46:21 CEST")
end <- begin + refresh
mac_df <- data.frame()
mac_temp <- data.frame()
sec2milis <- function(x){x*1000}
delete <- TRUE
theme <- geom_col(color="#99ccff", fill="#99ccff")

shinyServer(function(input, output, session) {

  output$time_evol <- renderPrint({
    refresh <<- input$s
    cat(file=stderr(),"Before the API request", "\n")
    
    invalidateLater(sec2milis(refresh), session)
    mac_temp <<- getAllMacsByTimestamp(begin=begin, end=end)
    # woul not be necessary if filtering was done at the api
    # important: interval open on one side
    mac_temp <<- mac_temp[mac_temp$time >= begin & mac_temp$time < end,]
    
    cat(file=stderr(),"rows in temporal list", nrow(mac_temp), "\n")
    cat(file=stderr(),"columns in temporal list", ncol(mac_temp), "\n")
    cat(file=stderr(),"rows in permanent list", nrow(mac_df), "\n")
    cat(file=stderr(),"columns in permanent list", ncol(mac_df), "\n")
    names(mac_temp) <<- c("mac", "device", "ID","time", "type") # important dont move
    # solves match.names problems in rbind
    mac_df <<- rbind(mac_df, mac_temp)
    cat(file=stderr(), "names of permanent and temporal dataset", 
        names(mac_df), names(mac_temp), "\n")
    print(begin)
    print(end)
    begin <<- begin + refresh
    end <<- end + refresh
  })
  
  
  output$macs_per_second <- renderPlot({
    invalidateLater(sec2milis(refresh), session)
    interval_mac_count <- count_macs_interval(mac_temp, "time", "mac", "1 sec")
    plot_date_count(interval_mac_count, "time", "mac_count", "1 sec", theme)
  })
  
  output$macs_per_second_total <- renderPlot({
    invalidateLater(sec2milis(refresh), session)
    interval_mac_count <- count_macs_interval(mac_df, "time", "mac", "1 sec")
    plot_date_count(interval_mac_count, "time", "mac_count", "1 sec", theme)
    
  })
  
  output$time_per_mac <- renderPlot({
  #  ## straw
  #  getMinOrMax <- function(mac, data, min_or_max, mac_col, time_col){
  #    min_or_max(data[data[mac_col]==mac, time_col])
  #   }
  # mapply(f, unlist(lista_macs), MoreArgs=list(data=macs, mac_col="mac", min_or_max=min, time_col="time"))
  # ##
  # x <- runif(n_distinct(mac_df$MAC), min = 0, max = as.numeric(end-begin)/15)
  # plot(x)

  })
  
  # amount of unique macs in the interval
  output$new_macs_per_second <- renderPlot({
    invalidateLater(sec2milis(refresh), session)
    new_macs_count <- count_new_macs_interval(mac_temp, "time", "mac", "1 sec")
    plot_date_count(new_macs_count, "time", "mac_count", "1 sec", theme)
  })
  
  output$time_between_bursts <- renderPlot({
    invalidateLater(sec2milis(refresh), session)
    t_bursts <- time_between_bursts(mac_df, "mac", "time")
    hist(as.numeric(t_bursts$t_burst), main="Average time between bursts", col="#99ccff", fill="#99ccff")
  })

  # Generates the static report
  observeEvent(input$static_annalyse, {
    render("../static-report.Rmd")
    insertUI(
      selector = "#content_iframe",
      where = "beforeEnd",
      ui = includeHTML("../static-report.html")
    )
    session$sendCustomMessage(type = 'shiny_message', "Annalyse ready")
  })
})
