#' Wrapper for importing restricted MCOD data
#'
#' Restricted MCOD files carry sub-state geography (state and county of
#' residence and occurrence) for every data year. The public-use files stop
#' providing sub-state geography from 2005 (2004 is the last public year with
#' county); the restricted files carry it throughout. Restricted files come as
#' plaintext, fixed-width files. This helper function simply imports these
#' text files with known dictionaries.
#'
#' @param file path to restricted MCOD plaintext file
#' @param year_x year of MCOD data
#'
#' @return dataframe
#' @seealso [import_mcod_fwf()] for the public (and exported) entry point.
#' @keywords internal
.import_restricted_data <- function(file, year_x) {
    .import_mcod_data(file, year_x, tier = "restricted")
}
