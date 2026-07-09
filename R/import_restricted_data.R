#' Wrapper for importing restricted MCOD data
#'
#' Restricted MCOD data contains geographical location (for years after 2004),
#' that the public-use files do not contain. Further, restricted files come as
#' plaintext, fixed-width files. This helper function simply imports these
#' text files with known dictionaries.
#'
#' @param file path to restricted MCOD plaintext file
#' @param year_x year of MCOD data
#'
#' @return dataframe
#' @seealso [import_mcod_fwf()] for the public (and exported) entry point.
.import_restricted_data <- function(file, year_x) {
    .import_mcod_data(file, year_x, tier = "restricted")
}
