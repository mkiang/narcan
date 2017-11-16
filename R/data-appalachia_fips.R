#' Dataframe of Appalachian counties with name and FIPS codes
#'
#' A dataset that contains all 420 counties belonging to the Appalachia region.
#'
#' @docType data
#'
#' @format A data frame with 420 rows and 7 columns
#' \describe{
#'   \item{st_abbrev}{chr, state abbreviation}
#'   \item{state}{chr, full state name}
#'   \item{county}{chr, short name for the county}
#'   \item{county_name}{chr, full county name with state}
#'   \item{state_fips}{chr, two character state FIPS code}
#'   \item{county_fips}{chr, three character county FIPS code}
#'   \item{fipschar}{chr, five character full FIPS code}
#' }
#' @source \url{https://github.com/davemistich/election-appalachia/}
#' @keywords datasets
"appalachia_fips"
