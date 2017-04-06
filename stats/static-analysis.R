library(dplyr)
library(tidyr)
library(scales)
library(ggplot2)

#' Reads csv with macs, timestamp, antenna ID and mac type (random or fixed)
#' @param filepath string. Path to file
#' @param timeformat string. 
#' @returns dataframe with timestamps in POSIXct format
read_capture <- function(filepath, timeformat = "%Y/%m/%d-%H:%M:%S"){
  data <- read.csv(filepath)
  data$time <- as.POSIXct(strptime(data$time, timeformat))
  data
}

#' Returns appearances of each mac for the whole interval
#' @note equals ipython static function "mac_occurs"
#' @param mac_col string or number. Column name of the mac variable
mac_count_distribution <- function(data, mac_col){
 counted <- data %>% count_(mac_col) 
 names(counted) <- c(mac_col, "mac_count")
 counted
}

#' Counts appearances of each unique mac by interval
#' @param data macs dataframe
#' @param time_col string or number. Column of the timestamp variable
#' @param mac_col string or number. Column of the mac variable
#' @param interval passe to cut. Format: "integer unit". See ?cut
#' @returns dataframe with 3 columns: time_col, mac and count. 
#'          many macs per interval
#' @example: distinct_mac(df, "time", "mac", "2 sec")
distinct_macs_interval <- function(data, time_col, mac_col, interval){
  intervals <- cut(data[[time_col]], interval)
  data[,time_col] <- intervals
  counted <- data %>% group_by_(time_col) %>% count_(mac_col)
  names(counted) <- c(time_col, mac_col, "mac_count")
  counted[,time_col] <- as.POSIXct(counted[,time_col])
  counted
}

#' Counts appearances of all macs by interval
#' @note equals ipython static function "origin_activity"
#' @param data macs dataframe
#' @param time_col string or number. Column of the timestamp variable
#' @param mac_col string or number. Column of the mac variable
#' @param interval passe to cut. Format: "integer unit". See ?cut
#' @returns dataframe with 2 columns: time_col and mac_count. 
#'          the timestamps are not unique, as many as macs
#' @example: distinct_mac(df, "time", "mac", "2 sec")
count_macs_interval <- function(data, time_col, mac_col, interval){
  intervals <- cut(data[[time_col]], interval)
  data[,time_col] <- intervals
  counted <- data %>% group_by_(time_col) %>% count_(mac_col) %>% summarise(mac_count = sum(n))
  # note: every operation turns data into a factor.
  counted[[time_col]] <- as.POSIXct(counted[[time_col]])
  counted
}

#' Counts appearances of macs by interval, only if they are new
#' @note equals ipython static function "origin_activity"
#' @param data macs dataframe
#' @param time_col string or number. Column of the timestamp variable
#' @param mac_col string or number. Column of the mac variable
#' @param interval passe to cut. Format: "integer unit". See ?cut
#' @returns dataframe with 2 columns: time_col and mac_count. 
#'          the timestamps are not unique, as many as macs
#' @example: distinct_mac(df, "time", "mac", "2 sec")
count_new_macs_interval <- function(data, time_col, mac_col, interval){
  intervals <- cut(data[[time_col]], interval)
  data[,time_col] <- intervals
  # FIXME: time is the column name in NSE (non standard evaluation), should 
  # be obtained from time_col somehow
  counted <- data %>% group_by_(mac_col) %>% top_n(-1, time) %>% ungroup() %>% 
    distinct_(mac_col,time_col) %>% # top_n does not remove duplicates
    # so far, selected first appearances for each mac
    # then macs are counted for each interval
    group_by_(time_col) %>% count_(mac_col) %>% summarise(mac_count = sum(n))
  counted[[time_col]] <- as.POSIXct(counted[[time_col]])
  counted
}

#' Evolution of new macs seen by the system. Always increases (not devices inside)
#' @param count_col string or number. Column with counted macs
#' @param data dataframe
new_macs_accumulated <- function(data, count_col, time_col){
  # FIXME: time, mac_count is NSE, must be converted somehow
  data %>% transmute(time,macs_inside = cumsum(mac_count)) 
}

plot_date_count <- function(data, date_col, count_col, time_breaks, 
                            geom = geom_col()){
  # aes_string allows passing columns as strings
  ggplot(data, aes_string(x = date_col, y = count_col)) + geom +
    scale_x_datetime(breaks = date_breaks(time_breaks), date_labels = "%M:%S")
}
  

