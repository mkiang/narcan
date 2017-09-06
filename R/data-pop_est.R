#' Dataframe of annual population counts by age and race, 1979-2015
#'
#' A data set containing annual population counts by age (5-year bins,
#' 18 groups), sex, and race. All data are from the US Census Bureau Population
#' Estimates Program.
#'
#' @docType data
#'
#' @format A data frame with 7992 rows and 6 columns
#' \describe{
#'   \item{year}{year of observation (int)}
#'   \item{age}{starting age for that age category}
#'   \item{age_cat}{age category in human readable form}
#'   \item{sex}{male, female, or both}
#'   \item{race}{race/ethnicity group}
#'   \item{pop}{number of people for year/age/race/sex combination}
#' }
#' @source \url{https://www.census.gov/programs-surveys/popest.html}
#' @keywords datasets
"pop_est"
