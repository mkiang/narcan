#' Replace state abbreviations with their corresponding FIPS code
#'
#' @param column a vector of strings with state abbreviations
#'
#' @return a new vector with state FIPS
#' @importFrom stringr str_replace_all
#' @export
#' @examples
#' state_abbrev_to_fips(c("AK", "AL", "MA", "CA"))
#' state_abbrev_to_fips(c("AK202", "AL001", "MA101", "CA321"))

state_abbrev_to_fips <- function(column) {
    rep_pattern <- narcan::st_fips_map$fips
    names(rep_pattern) <- narcan::st_fips_map$abbrev

    new_col <- stringr::str_replace_all(column, pattern = rep_pattern)

    return(new_col)
}
