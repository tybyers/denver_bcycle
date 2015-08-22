# Denver B-Cycle 2014 Ridership 

Tyler Byers

tybyers@gmail.com

August 23, 2015

## Project Summary

This is my final project for University of Washington's Methods for Data Analysis class, course #2 of 3 in the [Data Science Certificate program](http://www.pce.uw.edu/certificates/data-science.html).  This project looks at public data from the [Denver B-cycle](https://denver.bcycle.com/) program, which is merged with distance data from Google Maps and weather data from [forecast.io](http://www.forecast.io).

## Project Files
 
 The following project files are in this project directory:
 
 * [README.md](https://github.com/tybyers/denver_bcycle/blob/master/README.md) -- This document, with project description.
 * [Denver_B-Cycle_2014.md](https://github.com/tybyers/denver_bcycle/blob/master/Denver_B-Cycle_2014.md) -- Final project writeup.
 * [bcycle_final_script.R](https://github.com/tybyers/denver_bcycle/blob/master/bcycle_final_script.R) -- Production-level final script.
 * [exploring_bcycle_data.Rmd](https://github.com/tybyers/denver_bcycle/blob/master/exploring_bcycle_data.Rmd) -- Contains code for data-set building (some processes are fairly complex and time-intensive and would not make sense to build in a production-level script) and initial data explorations.
 * [./data](https://github.com/tybyers/denver_bcycle/tree/master/data) -- Directory containing data files used in the scripts.
 * [./figures](https://github.com/tybyers/denver_bcycle/tree/master/figures) -- Directory with figures loaded into the final project writeup.

## Data Sources

 * B-Cycle Rider Data: https://denver.bcycle.com/company, Denver B-Cycle Trip Data 2014 link at bottom (https://denver.bcycle.com/docs/librariesprovider34/default-document-library/2014denverbcycletripdata_public.xlsx?sfvrsn=2).
 * B-Cycle Station Locations: From the Google Maps locations on https://denver.bcycle.com/.  I was unable to easily programmatically access the map layer data, so collected these addresses "manually."
 * Weather Data: Downloaded from [forecast.io](http://www.forecast.io) via the developer API. 
 * ggmap package in R: https://cran.r-project.org/web/packages/ggmap/index.html.  Used to access between-station distances. 
 * Holidays 2014: [opm.gov](https://www.opm.gov/policy-data-oversight/snow-dismissal-procedures/federal-holidays/#url=2014) and Google search for [Cesar Chavez Day](https://www.google.com/webhp?sourceid=chrome-instant&ion=1&espv=2&ie=UTF-8#q=cesar%20chavez%20day%202014), the latter of which is a City of Denver public holiday.

## Analysis Software

All data analysis was done using R in RStudio.  The following R packages are required in order to re-run the final R-script and the Data Building/Exploratory Analysis file `exploring_bcycle_data.Rmd`.  Note that to fully run the exploring_bcycle_data.Rmd file, you will need your own forecast.io developer API key, and will need to run the `kiosk_pairs` code chunk over the course of at least 3 days (there is a limit of 2500 calls to Google Distance Matrix API using the `mapdist` code per day).

```r
library(ggplot2); library(dplyr); library(tidyr)
library(lubridate); library(xml2); library(readxl)
library(ggmap);
```

## Comparison to B-cycle Annual Report

A tip of the hat to Denver B-Cycle's [annual report](https://denver.bcycle.com/docs/librariesprovider34/default-document-library/annual-reports/2014-denver-bike-sharing-annual-report.pdf?sfvrsn=2). Due to some likely differences in data processing and analysis, some of our conclusions (such as number of trips and miles ridden) are different than the official B-cycle analysis. However, my analysis couldn't have been possible without first reading their analysis and learning about the data, and certainly would not have been possible without the public availability of their ridership data.

