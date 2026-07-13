#' Replace state abbreviations with their corresponding FIPS code
#'
#' Only the 50 US states and the District of Columbia are recognized; territory
#' abbreviations (e.g. `"PR"`, `"GU"`, `"VI"`) return `NA`, as narcan is US-only.
#'
#' @param column a vector of strings with state abbreviations
#'
#' @return a new vector with state FIPS (`NA` for unrecognized abbreviations)
#' @export
#' @examples
#' state_abbrev_to_fips(c("CA", "NY", "TX"))
state_abbrev_to_fips <- function(column) {
    ## Zero-pad to two digits so the result matches add_county_fips() (e.g. CA
    ## -> "06", not "6"). Unrecognized or wrong-case abbreviations map to NA
    ## (with a warning) instead of silently passing through unconverted, which
    ## would fail any downstream FIPS-keyed join with no signal.
    lookup <- sprintf("%02d", narcan::st_fips_map$fips)
    names(lookup) <- narcan::st_fips_map$abbrev

    new_col <- unname(lookup[column])

    unmatched <- unique(column[is.na(new_col) & !is.na(column)])
    if (length(unmatched) > 0) {
        warning("Unrecognized state abbreviation(s) set to NA: ",
                paste(sort(unmatched), collapse = ", "),
                ". Expected uppercase two-letter USPS codes.", call. = FALSE)
    }

    new_col
}
