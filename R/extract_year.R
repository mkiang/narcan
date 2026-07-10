#' Helper function that extracts year from a dataframe and raises error
#' if more than one.
#'
#' MCOD files name the year column `year` from data year 1996 onward but
#' `datayear` for 1979-1995. This checks `year` first, then falls back to
#' `datayear`, and errors if neither column is present.
#'
#' @param df dataframe to extract year from
#'
#' @return year as integer
.extract_year <- function(df) {
    if (!is.null(df$year)) {
        year <- unique(df$year)
    } else if (!is.null(df$datayear)) {
        year <- unique(df$datayear)
    } else {
        stop("No `year` or `datayear` column found.")
    }

    if (length(year) > 1) {
        stop("Too many years.")
    }

    return(year)
}
