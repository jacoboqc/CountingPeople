library(dplyr)
library(tidyr)
library(httr)

getAllMacs <- function(url, timeformat = "%Y/%m/%d-%H:%M:%S"){
  r <- GET(url, accept("text/csv"))  
  data <- read.csv(text=content(r, "text"), header=T)
  data$time <- as.POSIXct(strptime(data$time, timeformat))
  return(data)
}

getAllMacsByTimestamp <- function(endpoint = "http://localhost:3000/macs/interval" ,
                                  begin, end, timeformat = "%Y/%m/%d-%H:%M:%S"){
  # if none specified, function default is used
  begin <- format(begin, timeformat)
  end <- format(end, timeformat)
  url <- paste(endpoint,"?start=",begin,"&end=",end, sep="")
  r<- GET(url, accept("text/csv"))  
  data <- read.csv(text=content(r, "text"), header=T)
  # reads all columns as factors, convert if neccesary
  data$time <- as.POSIXct(strptime(data$time, timeformat))
  # more conversions...
  return(data)
}
