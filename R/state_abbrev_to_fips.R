#' Replace state abbreviations with their corresponding FIPS code
#'
#' @param column a vector of strings with state abbreviations
#'
#' @return a new vector with state FIPS
#' @importFrom stringr str_replace_all
#' @export

state_abbrev_to_fips <- function(column) {
    rep_pattern <- as.character(narcan::st_fips_map$fips)
    names(rep_pattern) <- narcan::st_fips_map$abbrev

    new_col <- stringr::str_replace_all(column, pattern = rep_pattern)

    return(new_col)
}
