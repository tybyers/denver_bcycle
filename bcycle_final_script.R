##--------------------------------------------
##
## Denver B-Cycle 2014 Ridership
##
## Class: PCE Data Science Methods Class
##
## Final Project
##
## See: https://github.com/tybyers/denver_bcycle for project details.
## 
##--------------------------------------------
## Author:
##
## Tyler Byers
## tybyers@gmail.com
## August 23, 2015
##


##----Import Libraries-----
require(logging)
require(dplyr)
require(ggplot2)
require(readr)
require(lubridate)
require(jsonlite)
require(ggmap)
Sys.setenv(TZ = 'America/Denver')
## Note: Since much of the data tidying occurred in the "exploring_bcycle_data.Rmd" 
#  file, we don't need to load all the same packages here.

##----Set Working Directory----
## Note to user: you will need to change this value!
setwd('~/UW_DataScience/MethodsDataAnalysis/final_project/')

read_bcycle_data <- function(data_path, logger = NA) {
    if (is.function(logger)){
        loginfo(paste('Unzipping and reading B-Cycle Data'),logger)
    }
    data <- read.csv(gzfile(data_path))  # DO want strings as factors
    
    if (is.function(logger)){
        loginfo(paste('Done reading B-Cycle Data from file.'),logger)
    }
    
    if (is.function(logger)){
        loginfo(paste('Formatting Date and Time columns'),logger)
    }
    
    data$return_date <- as.Date(data$return_date, tz = 'America/Denver')
    data$checkout_date <- as.Date(data$checkout_date, tz = 'America/Denver')
    data$return_datetime <- ymd_hms(data$return_datetime, 
                                    tz = 'America/Denver')
    data$checkout_datetime <- ymd_hms(data$checkout_datetime,
                                      tz = 'America/Denver')
    
    if (is.function(logger)){
        loginfo(paste('Done formatting Date and Time columns'),logger)
    }
    
    data
}

filter_bad_data <- function(data, logger = NA) {
    if (is.function(logger)){
        loginfo(paste('Unzipping and reading B-Cycle Data'),logger)
    }
    
    print('Status of returns locations:')
    print(table(data$ggmap_status))
    num_invalid <- table(data$ggmap_status)['return_invalid']
        
    # Filtering out all returns with a "return_invalid" location
    if (is.function(logger)){
        loginfo(paste('Filtering out', num_invalid, 
                      'lines with invalid return locations.'),logger)
    }
    data <- data %>% filter(ggmap_status != 'return_invalid')
    
    
    if (is.function(logger)){
        loginfo(paste('Inspecting duration of trips with same return',
                      'location as checkout location.'),logger)
    }
    p1 <- data %>% filter(ggmap_status == 'same_kiosk' & duration_mins <= 15) %>%
        ggplot(aes(x = duration_mins)) + 
        geom_histogram(binwidth = 1, fill = 'steelblue', color = 'black') +
        ggtitle('Trip Duration When Return and Checkout Kiosk the Same') +
        xlab('Duration Minutes') + ylab('Number of Trips') 
    print(p1)
    plot_filename <- './figures/duration_same_kiosk.png'
    png(filename = plot_filename)
    print(p1)
    dev.off()
    
    if (is.function(logger)){
        loginfo(paste('Saved histogram to file:', plot_filename),logger)
    }
    
    # Result -- filtering out all trips of duration = 1 min when returned
    #  to same kiosk
    nrow_samekiosk_dur1 <- nrow( data %>% filter(ggmap_status == 'same_kiosk' & 
                                                     duration_mins == 1))
    if (is.function(logger)){
        loginfo(paste('Filtering out', nrow_samekiosk_dur1, 
                      'trips with the same return kiosk as checkout kiosk',
                      'where the trip duration is 1 minute.'),logger)
    }
    data <- data %>% filter(ggmap_status != 'same_kiosk' | 
                            (ggmap_status == 'same_kiosk' & 
                                 duration_mins > 1))
    
    data
}

explore_bcycle_data <- function(data, logger = NA) {
    if (is.function(logger)){
        loginfo(paste('Summary Statistics of filtered B-cycle data.'),logger)
    }
    
    print(summary(data))
    print('Note: we do not have distances filled in for same_kiosk 
          returns yet.')
    print('Checkouts per program type:')
    print(sort(table(data$program), decreasing = TRUE))
    print('Users with the most checkouts')
    print(head(sort(table(data$user_id), decreasing = TRUE), 10))
    print('Checkouts per membership type:')
    print(head(sort(table(data$membership_type), decreasing = TRUE), 5))
    print('Top 10 most-used bikes:')
    print(head(sort(table(data$bike), decreasing = TRUE), 10))
    print('Top 10 most-used checkout kiosks:')
    print(head(sort(table(data$checkout_kiosk), decreasing = TRUE), 10))
    print('Least-used checkout kiosks:')
    print(head(sort(table(data$checkout_kiosk)), 10))
    print('Top 10 most-used return kiosks:')
    print(head(sort(table(data$return_kiosk), decreasing = TRUE), 10))
    print('Least-used return kiosks:')
    print(head(sort(table(data$return_kiosk)), 12))
}

map_kiosks <- function(data, logger = NA) {

    stations <- read_station_data(logger)

    if (is.function(logger)){
        loginfo(paste('Getting Denver Map'),logger)
    }
    
    denver <- get_map(location = 'Denver', zoom = 13)
    
    if (is.function(logger)){
        loginfo(paste('Mapping Checkout Kiosk Popularity'),logger)
    }
    
    kiosks_checkout <- data %>% group_by(checkout_kiosk) %>%
        summarise(n_checkouts = n())
    kiosks_checkout$checkout_kiosk <-
        as.character(kiosks_checkout$checkout_kiosk)
    names(stations)[1] <- 'checkout_kiosk'
    stations$checkout_kiosk <- as.character(stations$checkout_kiosk)
    kiosks_checkout <- left_join(kiosks_checkout, stations, 
                                 by = 'checkout_kiosk')
    p1 <- ggmap(denver) +
        geom_point(data = kiosks_checkout,
                   aes(x = lon, y = lat, size = n_checkouts)) + 
        xlab(NULL) + ylab(NULL) + 
        ggtitle('B-Cycle Kiosks by # of Checkouts, 2014')
    print(p1)
    p1_filename <- './figures/checkout_kiosk_map.png'
    png(filename = p1_filename, width = 960, height = 960)
    print(p1)
    dev.off()
    if (is.function(logger)){
        loginfo(paste('Saved map to file:', p1_filename),logger)
    }
    
    
    if (is.function(logger)){
        loginfo(paste('Mapping Return Kiosk Popularity'),logger)
    }
    kiosks_return <- data %>% group_by(return_kiosk) %>%
        summarise(n_returns = n())
    kiosks_return$return_kiosk <- 
        as.character(kiosks_return$return_kiosk)
    names(stations)[1] <- 'return_kiosk'
    kiosks_return <- left_join(kiosks_return, stations, 
                                 by = 'return_kiosk')
    p2 <- ggmap(denver) +
        geom_point(data = kiosks_return,
                   aes(x = lon, y = lat, size = n_returns)) + 
        xlab(NULL) + ylab(NULL) + 
        ggtitle('B-Cycle Kiosks by # of Returns, 2014')
    print(p2)
    p2_filename <- './figures/return_kiosk_map.png'
    png(filename = p2_filename, width = 960, height = 960)
    print(p2)
    dev.off()
    if (is.function(logger)){
        loginfo(paste('Saved map to file:', p2_filename),logger)
    }
    
}

read_station_data <- function(logger = NA) {
    
    if (is.function(logger)){
        loginfo(paste('Getting Station Geo Data.'),logger)
    }
    
    station_path <- paste0(getwd(), '/data/stations_address_geocode.csv')
    
    stations <- read_csv(station_path)
    
    stations
}

fill_samestation_distances <- function(data, logger) {
    if (is.function(logger)){
        loginfo(paste('Filling in distances for checkouts/returns',
                      'to the same station.'),logger)
    }
    
    print(paste('To fill in distances when the checkout and return',
                'kiosks are the same, going to use the naive', 
                'assumption that the people are riding, on average',
                'the same average speed as the average speed when',
                'they are riding between stations.'))
    # speed in "miles per minute"
    speeds <- (data$ggmap_dist/data$duration_mins)
    avg_speed <- mean(speeds, na.rm = TRUE)
    data$duration_mins <- as.numeric(data$duration_mins)
    data$estimated_distance <- apply(data, 1, function(d_row) {
        if(is.na(d_row['ggmap_dist'])) {
            dist <- avg_speed * as.numeric(d_row['duration_mins'])
            if(dist > 5) {  # cap estimated distance at 5 miles
                dist = 5
            }
        } else {
            dist <- d_row['ggmap_dist']
        }
        dist
    })
    data$estimated_distance <- as.numeric(data$estimated_distance)
    print(summary(data$estimated_distance))
    print(paste('Estimated total distance ridden:',
                round(sum(data$estimated_distance)), 'miles.'))
    
    if (is.function(logger)){
        loginfo(paste('Done filling in distances for checkouts/returns',
                      'to the same station.'),logger)
    }
    
    data
}

load_weather_data <- function(logger = NA) {
    if (is.function(logger)){
        loginfo(paste('Loading weather data from JSON.'),logger)
    }
    
    weather_dir <- paste0(getwd(), '/data/weather/')
    weather_data <- data.frame()
    for (json in dir(weather_dir, full.names=TRUE)) {
        weather_day <- fromJSON(json, flatten=TRUE)$hourly$data
        weather_day2 <- data.frame(
            time = as.POSIXct(weather_day$time, origin = '1970-01-01',
                              tz = 'America/Denver'),
            temperature = weather_day$temperature,
            dew_point = weather_day$dewPoint,
            sky = as.factor(tolower(weather_day$summary)),
            humidity = weather_day$humidity
        )
        # cloudCover was missing from at least one day
        if('cloudCover' %in% names(weather_day)) {
            weather_day2$cloud_cover <- weather_day$cloudCover
        }
        else {
            weather_day2$cloud_cover <- NA
        }
        if (exists('weather_data')) {
            weather_data = rbind(weather_data, weather_day2)
        } else {
            weather_data = weather_day2
        }
    }
    
    weather_data <- distinct(weather_data, time)
    names(weather_data)[which(names(weather_data) == 'time')] = 'datetime'
    
    if (is.function(logger)){
        loginfo(paste('Done loading weather data from JSON.'),logger)
    }
    
    weather_data
}

calendar_variables_bcycle <- function(data, logger = NA, holidays = FALSE) {
    if (is.function(logger)){
        loginfo(paste('Calculating calendar variables for bcycle'),logger)
    }
    data$checkout_month <- month(data$checkout_date)
    data$checkout_week <- week(data$checkout_date)
    data$checkout_wday <- wday(data$checkout_date)
    if('checkout_datetime' %in% names(data)) {
        data$checkout_hour <- hour(data$checkout_datetime)   
    }
    if(holidays) {
        h_days <- c('2014-01-01', '2014-01-20', '2014-02-17', '2014-03-31',
                      '2014-05-26', '2014-07-04', '2014-09-01', '2014-10-13',
                      '2014-11-11', '2014-11-27', '2014-12-25')
        data$checkout_date <- as.character(data$checkout_date)
        data$is_holiday <- sapply(data$checkout_date, function(date) {
            if(date %in% h_days){
                isholiday <- 1
            } else { isholiday <- 0 }
            isholiday
        })
    }
    if (is.function(logger)){
        loginfo(paste('Done calculating calendar variables for bcycle'),logger)
    }
    data
}

hourly_rider_stats <- function(data, logger = NA) {
    if (is.function(logger)){
        loginfo(paste('Getting hourly ridership stats, by checkout.'),logger)
    }
    
    data$checkout_hour <- hour(data$checkout_datetime)
    data_hourly <- data %>%
        group_by(checkout_date, checkout_hour) %>%
        summarise(num_checkouts = n(), avg_duration = mean(duration_mins),
                  avg_distance = mean(estimated_distance))
    
    if (is.function(logger)){
        loginfo(paste('Done getting hourly ridership stats, by checkout.'),
                logger)
    }
    
    data_hourly <- calendar_variables_bcycle(data_hourly, logger,
                                             holidays = TRUE)
    
    data_hourly
}

# Do various plots of checkouts by calendar factors
plots_of_checkouts <- function(data, logger = NA) {
    if (is.function(logger)){
        loginfo(paste('Plotting Checkouts by Calendar Variables'),
                logger)
    }
    
    data_byhour <- data %>%
        group_by(checkout_hour) %>%
        summarise(n_checkouts = n(), avg_distance = mean(estimated_distance),
                  avg_duration = mean(duration_mins))
    p1 <- ggplot(data_byhour, aes(x = checkout_hour, y = n_checkouts)) +
        geom_line() + geom_point() + xlab('Checkout Hour of Day') +
        ylab('Number of Checkouts, 2014') + 
        ggtitle('Total Number of Checkouts by Hour of the Day')
    print(p1)
    p1_filename <- './figures/checkouts_by_hourofday.png'
    png(filename = p1_filename)
    print(p1)
    dev.off()
    if (is.function(logger)){
        loginfo(paste('Saved plot to file:', p1_filename),logger)
    }
    
    p1_1 <- ggplot(data_byhour, aes(x = checkout_hour, y = avg_distance)) +
        geom_line() + geom_point() + xlab('Checkout Hour of Day') +
        ylab('Average Distance Ridden') + 
        ggtitle('Average Distance Ridden by Hour of the Day')
    print(p1_1)
    p1_1_filename <- './figures/avgMiles_by_hourofday.png'
    png(filename = p1_1_filename)
    print(p1_1)
    dev.off()
    if (is.function(logger)){
        loginfo(paste('Saved plot to file:', p1_1_filename),logger)
    }
    
    data_bywday_hour <- data %>%
        group_by(checkout_wday, checkout_hour) %>%
        summarise(n_checkouts = n(), avg_distance = mean(estimated_distance),
                  avg_duration = mean(duration_mins))
    p2 <- ggplot(data_bywday_hour, aes(x = checkout_hour, y = n_checkouts)) +
        geom_line() + geom_point() + 
        facet_wrap(~checkout_wday) + 
        xlab('Checkout Hour of Day per Weekday (Sunday = 1)') +
        ylab('Number of Checkouts, 2014') + 
        ggtitle('Total Number of Checkouts by Hour of the Day per Weekday')
    print(p2)
    p2_filename <- './figures/numcheckouts_by_hourofday_perweekday.png'
    png(filename = p2_filename)
    print(p2)
    dev.off()
    if (is.function(logger)){
        loginfo(paste('Saved plot to file:', p2_filename),logger)
    }
    
    p2_2 <- ggplot(data_bywday_hour, aes(x = checkout_hour, y = avg_distance)) +
        geom_line() + geom_point() + 
        facet_wrap(~checkout_wday) + 
        xlab('Checkout Hour of Day per Weekday (Sunday = 1)') +
        ylab('Average Distance Ridden') + 
        ggtitle('Avg Distance Ridden by Hour of the Day per Weekday') +
        scale_y_continuous(limits = c(1.1, 2.4))
    print(p2_2)
    p2_2_filename <- './figures/distridden_by_hourofday_perweekday.png'
    png(filename = p2_2_filename)
    print(p2_2)
    dev.off()
    if (is.function(logger)){
        loginfo(paste('Saved plot to file:', p2_2_filename),logger)
    }
    
    data_by_month <- data %>% 
        group_by(checkout_month) %>% 
        summarise(n_checkouts = n(), avg_distance = mean(estimated_distance))
    p3 <- ggplot(data_by_month, aes(x = checkout_month, y = n_checkouts)) + 
        geom_bar(stat = 'identity') +
        scale_x_continuous(breaks = c(2,4,6,8,10)) +
        ggtitle('Total Number of Checkouts by Month') +
        xlab('Month of Year 2014') + ylab('Total Number of Checkouts')
    print(p3)
    p3_filename <- './figures/totalcheckouts_bymonth.png'
    png(filename = p3_filename)
    print(p3)
    dev.off()
    if (is.function(logger)){
        loginfo(paste('Saved plot to file:', p3_filename),logger)
    }
    
    p3_3 <- ggplot(data_by_month, aes(x = checkout_month, y = avg_distance)) + 
        geom_bar(stat = 'identity') +
        scale_x_continuous(breaks = c(2,4,6,8,10)) +
        ggtitle('Total Number of Checkouts by Month') +
        xlab('Month of Year 2014') + ylab('Avg Miles Ridden Per Ride')
    print(p3_3)   
    p3_3_filename <- './figures/avgMiles_bymonth.png'
    png(filename = p3_3_filename)
    print(p3_3)
    dev.off()
    if (is.function(logger)){
        loginfo(paste('Saved plot to file:', p3_3_filename),logger)
    }
    
    if (is.function(logger)){
        loginfo(paste('Done plotting Checkouts by Calendar Variables'),
                logger)
    }
    
}

merge_bcycle_weather <- function(bcycle_data, weather, logger = NA) {
    if (is.function(logger)){
        loginfo(paste('Merging B-cycle and Weather Data'),
                logger)
    }
    
    bcycle_data$datetime <- ymd_h(paste(bcycle_data$checkout_date,
                                   bcycle_data$checkout_hour),
                                  tz = 'America/Denver')
    
    merged_data <- left_join(weather, bcycle_data, by = 'datetime')
    merged_data <- merged_data %>% 
        select(c(-checkout_date, -checkout_hour, -checkout_month, 
                 -checkout_week, -checkout_wday, -is_holiday))
    
    merged_data[is.na(merged_data$num_checkouts), 
                c('num_checkouts', 'avg_duration', 'avg_distance')] <- 0
    merged_data$wday <- wday(merged_data$datetime)
    merged_data$hour <- hour(merged_data$datetime)
    h_days <- c('2014-01-01', '2014-01-20', '2014-02-17', '2014-03-31',
                '2014-05-26', '2014-07-04', '2014-09-01', '2014-10-13',
                '2014-11-11', '2014-11-27', '2014-12-25')
    merged_data$is_holiday <-
        sapply(as.character(as.Date(merged_data$datetime, 
                                    tz = 'America/Denver')),
                              function(date) {
        if(date %in% h_days){
            isholiday <- 1
        } else { isholiday <- 0 }
        isholiday
    })
    
    if (is.function(logger)){
        loginfo(paste('Done merging B-cycle and Weather Data'),
                logger)
    }
    
    merged_data
}

find_top_days <- function(merged_data, logger = NA) {
    if (is.function(logger)){
        loginfo(paste('Finding highest and lowest days of ridership'),
                logger)
    }
    
    merged_data$date <- as.Date(merged_data$datetime,
                                tz = 'America/Denver')
    
    data_by_date <- merged_data %>%
        group_by(date) %>%
        summarise(total_checkouts = sum(num_checkouts), 
                  max_temp = max(temperature),
                  min_temp = min(temperature))
    data_by_date$weekday <- weekdays(data_by_date$date)
    
    print('Top 5 Days by Total Number of Checkouts:')
    print(data_by_date %>% arrange(-total_checkouts) %>%
              top_n(5, total_checkouts))
    
    print('Top 5 Days by Least Number of Checkouts:')
    print(data_by_date %>% arrange(total_checkouts) %>%
              top_n(5, -total_checkouts))
}

plot_weather_checkouts <- function(merged_data, logger = NA) {
    if (is.function(logger)){
        loginfo(paste('Plotting temperature vs checkouts.'),
                logger)
    }
    
    p1 <- ggplot(merged_data, aes(x = temperature, y = num_checkouts)) +
        geom_point(alpha = 0.25) + geom_smooth(method = 'loess') +
        xlab('Temperature (F)') +
        ylab('Number of Checkouts') + 
        ggtitle('Number of Checkouts vs. Temperature')
    print(p1)
    p1_filename <- './figures/checkouts_vs_temperature.png'
    png(p1_filename)
    print(p1)
    dev.off()
    if (is.function(logger)){
        loginfo(paste('Saved plot to file:', p1_filename),logger)
    }
}

fit_linear_model <- function(merged_data, logger = NA) {
    if (is.function(logger)){
        loginfo(paste('Fitting Linear Model to Data'),
                logger)
    }
    
    # Hourly and wday variables need to be factors
    merged_data$hour <- as.factor(merged_data$hour)
    merged_data$wday <- as.factor(merged_data$wday)
    merged_data$temp_sq <- (merged_data$temperature)**2
    
    fol <- formula(num_checkouts ~ temperature + humidity + wday + 
                       temp_sq + hour + is_holiday + cloud_cover)
    fit <- lm(fol, merged_data)
    fit
}

##----Run Main Function ----
if(interactive()){
    
    ##----Setup Test Logger-----
    basicConfig()
    addHandler(writeToFile, file="./testing.log", level='DEBUG')
    logger <- writeToFile

    ##----Read B-cycle Data
    # Note the data are gzipped -- is 79 MB inflated
    if(!('bcycle' %in% ls())) {
        bcycle_path <- paste0(getwd(), '/data/bcycle_2014_ggmap_distances.csv.gz')
        bcycle <- read_bcycle_data(bcycle_path, logger)
    } else {
            loginfo(paste('Dataframe \'bcycle\' already exists.',
                          'Not reading from file.  If this is in error,',
                          'please `rm(bcycle)` from workspace and',
                          'try again.'))
    }
    
    bcycle_filtered <- filter_bad_data(bcycle, logger)
    explore_bcycle_data(bcycle_filtered, logger)
    map_kiosks(bcycle_filtered, logger)
    bcycle_filtered <- fill_samestation_distances(bcycle_filtered, logger)
    bcycle_filtered <- calendar_variables_bcycle(bcycle_filtered, logger)
    plots_of_checkouts(bcycle_filtered, logger)
    bcycle_hourly <- hourly_rider_stats(bcycle_filtered, logger)
    weather <- load_weather_data(logger)
    merged_data <- merge_bcycle_weather(bcycle_hourly, weather, logger)
    find_top_days(merged_data, logger)
    plot_weather_checkouts(merged_data, logger)
    lm_fit <- fit_linear_model(merged_data, logger)
    print(summary(lm_fit))
}