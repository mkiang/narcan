#' Create a categorical race column from standardized race column
#'
#' From 1979 to 2015, the race variable in MCOD files underwent several
#' changes. This function creates a categorical race variable based on
#' the standardized race column created by remap_race().
#'
#' @param race_column race column created from remap_race()
#'
#' @return factor
#' @export
#'
#' @examples
#' categorize_race(c(0, 1, 1, 1, 0:7, 99))
categorize_race <- function(race_column) {
    ## Assumes our standardized race codes (i.e., remap_race()) and then
    ## converts to categorical
    x <- factor(race_column,
                levels = c(0:7, 99),
                labels = c("total", "white", "black", "american_indian",
                           "chinese", "japanese", "hawaiian", "filipino",
                           "other"),
                ordered = TRUE)
    return(x)
}
