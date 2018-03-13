#' Dataframe of live births in the US from 2003-2016 by race/ethnicity and age.
#'
#' A data set containing number of live births in the US from 2003 to 2016 by
#' race/ethnicity and five-year age group (<15, 15-19, ... >50).
#'
#' @docType data
#'
#' @format A data frame with 1134 rows and 4 columns
#' \describe{
#'   \item{mother_age}{int, first year of five-year age bin for the mother}
#'   \item{births}{int, number o}f births
#'   \item{m_race_eth}{factor, mother's race/ethnicity}
#'   \item{year}{int, year of observation}
#' }
#' @source \url{https://www.cdc.gov/nchs/fastats/births.htm}
#' @keywords datasets
"live_births"
