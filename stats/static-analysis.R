library(dplyr)
library(tidyr)

#' Reads csv with macs, timestamp, antenna ID and mac type (random or fixed)
#' @param filepath string. Path to file
#' @param timeformat string. 
#' @returns dataframe with timestamps in POSIXct format
read_capture <- function(filepath, timeformat = "%Y/%m/%d-%H:%M:%S"){
  data <- read.csv(filepath)
  data$time <- as.POSIXct(strptime(data$time, timeformat))
  data
}

#' Counts appearances of each unique mac by interval
#' @param data macs dataframe
#' @param time_col string. Column name of the timestamp variable
#' @param mac_col string. Column name of the mac variable
#' @param interval passe to cut. Format: "integer unit". See ?cut
#' @returns dataframe with 3 columns: timestamp, mac and count. 
#'          the timestamps are not unique, as many as macs
#' @example: distinct_mac(df, "time", "mac", "2 sec")
distinct_mac_interval <- function(data, time_col, mac_col, interval){
  intervals <- cut(data[[time_col]], interval)
  data[,time_col] <- intervals
  data %>% group_by_(time_col) %>% count_(mac_col)
  names(data) <- c(time_col, mac_col, "mac_count")
  data
}

#' Counts appearances of all macs by interval
#' @note equals ipython static function "origin_activity"
#' @param data macs dataframe
#' @param time_col string. Column name of the timestamp variable
#' @param mac_col string. Column name of the mac variable
#' @param interval passe to cut. Format: "integer unit". See ?cut
#' @returns dataframe with 2 columns: timestamp and mac_count. 
#'          the timestamps are not unique, as many as macs
#' @example: distinct_mac(df, "time", "mac", "2 sec")
mac_count_interval <- function(data, time_col, mac_col, interval){
  intervals <- cut(data[[time_col]], interval)
  data[,time_col] <- intervals
  data %>% group_by_(time_col) %>% count_(mac_col) %>% summarise(mac_count = sum(n))
}

