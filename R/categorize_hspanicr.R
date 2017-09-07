#' Create a categorical Hispanic column from the hspanicr column
#'
#' The hspanicr column was not introduced until 1987 and not all years have
#' all possible Hispanic options. This creates a categorical variable so
#' functions like tidyr::complete() will expand rows that have no observations.
#'
#' @param hspanicr_column hspanicr column from MCOD dataframe
#'
#' @return factor
#' @export
#'
#' @examples
#' categorize_hspanicr(c(1:5, NA, 9, 8, 4))
categorize_hspanicr <- function(hspanicr_column) {
    ## Just categorizes the hspanicr column so we can use tidyr::complete()
    x <- factor(hspanicr_column,
                levels = 1:9,
                labels = c("mexican", "puerto_rican", "cuban",
                           "central_south_america", "other_hispanic",
                           "nonhispanic_white", "nonhispanic_black",
                           "nonhispanic_other", "hispanic_unknown"),
                ordered = TRUE)
    return(x)
}
