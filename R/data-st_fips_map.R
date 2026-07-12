#' Mapping of state/territory name to abbreviation to FIPS code
#'
#' @docType data
#'
#' @format A data frame with 60 rows and 3 columns
#' \describe{
#'   \item{name}{character, name of territory}
#'   \item{abbrev}{character, abbreviation}
#'   \item{fips}{numeric, FIPS state code (zero-pad to 2 digits for a FIPS string)}
#'   \item{nchs}{numeric, NCHS state code (zero-pad to 2 digits)}
#' }
#' @source \url{https://en.wikipedia.org/wiki/Federal_Information_Processing_Standard_state_code}
#' @keywords datasets
"st_fips_map"
