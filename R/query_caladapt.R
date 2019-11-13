#' Query Cal-Adapt data
#'
#' @param var Name of the variable
#' @param model Name of the climate model
#' @param scenario Name of the climate scenario
#' @param coords Coordinates of the location for which data is desired
#' @param type Return data ('events') or 'rasters'
#' @param timestep Annual ('year'), monthly, or daily data
#' @param stat Stat desired; defaults to 'mean'; unclear what other options are
#' @param url Cal-Adapt API URL; defaults to 'http://api.cal-adapt.org/api/series/'
#'
#' @return For type = 'events', returns a tibble. Untested for type = 'rasters'.
#' @details Options for variables include 'tasmax' and 'tasmin' (max and min
#' temperatures) or 'pr' (precipitation). Note that precipitation is returned in
#' units of inches per day (even for timestep = 'year'), so will need to be
#' multiplied by 365 to generate annual totals. The full list of available models
#' and additional variables are provided here: https://berkeley-gif.github.io/caladapt-docs/data-catalog.html#climate-variables).
#' But note that only annual average tasmin, tasmax, and pr have been checked
#' against Cal-Adapt website outputs to date.
#'
#' Coordinates should be provided as a string in decimal degrees separated only
#' by a comma: 'long,lat'
#'
#' @export
#' @import httr
#' @import dplyr
#' @importFrom tibble tibble
#' @importFrom purrr map_chr
query_caladapt <- function(var, model, scenario, coords,
                           type = 'events', timestep = 'year', stat = 'mean',
                           url = 'http://api.cal-adapt.org/api/series/') {
  requireNamespace("purrr", quietly = TRUE)
  requireNamespace("tibble", quietly = TRUE)
  response <- httr::GET(url = paste0(url,
                                     paste(var, timestep, model, scenario, sep = '_'),
                                     '/', type, '/'),
                        query = list(pagesize = 100,
                                     g = paste0('{"type":"Point","coordinates":[', coords, ']}'),
                                     imperial = 'True',
                                     stat = stat))
  httr::warn_for_status(response)
  dat <- httr::content(response)
  tibble::tibble(index = purrr::map_chr(dat$index, .f = function(x) x[[1]]),
                 data = purrr::map_chr(dat$data, .f = function(x) x[[1]]),
                 source = dat$name) %>%
    mutate(index = as.Date(index),
           data = as.numeric(data)) %>%
    separate(source,
             into = c('variable', 'timestep', 'model', 'scenario'),
             sep = '_')
}