#' Mapping of US state name to abbreviation to FIPS and NCHS code
#'
#' The 50 US states plus the District of Columbia. narcan is US-only, so
#' territories and associated states (Puerto Rico, the U.S. Virgin Islands,
#' Guam, American Samoa, the Northern Mariana Islands, and the freely associated
#' states) are intentionally excluded: the public and restricted "us" MCOD files
#' narcan processes do not carry them, and their NCHS state codes in the source
#' are unreliable (e.g. American Samoa and the Northern Marianas both carry code
#' 62). This is a documented limitation -- territory geography is not supported.
#'
#' @docType data
#'
#' @format A data frame with 51 rows and 4 columns
#' \describe{
#'   \item{name}{character, name of the US state or the District of Columbia}
#'   \item{abbrev}{character, two-letter USPS abbreviation}
#'   \item{fips}{numeric, FIPS state code (zero-pad to 2 digits for a FIPS string)}
#'   \item{nchs}{numeric, NCHS state code (zero-pad to 2 digits)}
#' }
#' @source \url{https://en.wikipedia.org/wiki/Federal_Information_Processing_Standard_state_code}
#' @keywords datasets
"st_fips_map"
