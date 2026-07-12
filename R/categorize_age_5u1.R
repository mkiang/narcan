#' Create a categorical age column from a converted ager27 column
#'
#' Simply makes more meaningful labels on the age column. Assumes that the age
#' column was created from the convert_ager27() function. Allows for using
#' tidyr::complete() even when some age/year/race combinations have no
#' observations.
#'
#' @param ageu1_column age column created from convert_ager27u1()
#'
#' @return factor
#' @export
#'
#' @examples
#' categorize_age_5u1(c(0, 1, seq(5, 85, 5)))
categorize_age_5u1 <- function(ageu1_column) {
    ## Guard: a value not in the expected level set (<1, 1-4, then 5-year starts)
    ## becomes NA (factor() drops it silently). Warn (mirroring .warn_unmapped())
    ## so an unexpected age is visible rather than quietly lost.
    valid <- c(0, 1, seq(5, 85, 5))
    bad <- unique(ageu1_column[!is.na(ageu1_column) & !ageu1_column %in% valid])
    if (length(bad) > 0L) {
        warning(sprintf(paste0(
            "categorize_age_5u1(): %d value(s) outside the expected age level ",
            "set became NA: %s."), length(bad),
            paste(sort(bad), collapse = ", ")), call. = FALSE)
    }

    ## Just categorizes the age column into 5-year bins
    ## so we can use tidyr::complete()
    x <- factor(ageu1_column,
                levels = c(0, 1, seq(5, 85, 5)),
                labels = c("<1", "1-4",
                           paste0(seq(5, 84, 5), "-",
                                  seq(9, 84, 5)), "85+"),
                ordered = TRUE)
    return(x)
}
