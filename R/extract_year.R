#' Helper function that extracts year from a dataframe and raises error
#' if more than one.
#'
#' @param df dataframe to extract year from
#'
#' @return year as integer
.extract_year <- function(df) {
    year <- unique(df$year)

    if (length(year) > 1) {
        stop("Too many years.")
    }

    return(year)
}
