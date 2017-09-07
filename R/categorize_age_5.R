#' Create a categorical age column from a converted ager27 column
#'
#' Simply makes more meaningful labels on the age column. Assumes that the age
#' column was created from the convert_ager27() function. Allows for using
#' tidyr::complete() even when some age/year/race combinations have no
#' observations.
#'
#' @param age_column age column created from convert_ager27()
#'
#' @return factor
#' @export
#'
#' @examples
#' categorize_age_5(seq(0, 70, 5))
categorize_age_5 <- function(age_column) {
    ## Just categorizes the age column into 5-year bins
    ## so we can use tidyr::complete()
    x <- factor(age_column,
                levels = seq(0, 85, 5),
                labels = c(paste0(seq(0, 84, 5), "-",
                                  seq(4, 84, 5)), "85+"),
                ordered = TRUE)
    return(x)
}
