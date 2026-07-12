#' Converts the age27 variable in MCOD data to 5-year age groups
#'
#' @details Expects `ager27` in its documented domain (codes 1-27, where 27 is
#'   "age not stated" and maps to `NA`). A non-`NA` value outside 1-27 triggers a
#'   warning, since it would otherwise collapse silently into the 85+ bin or
#'   produce a negative age.
#'
#' @param icd_df an MCOD dataframe with age27 as a column
#' @param remove_age27 once a new column is created, remove the old age27
#'
#' @return dataframe
#' @importFrom dplyr mutate select
#' @export
#' @examples
#' df <- data.frame(ager27 = c(1, 10, 23, 27))
#' convert_ager27(df)
convert_ager27 <- function(icd_df, remove_age27 = TRUE) {
    ## Guard: AGER27 is documented to hold codes 1-27. A value outside 1:27 would
    ## silently collapse into the 85+ bin or produce a negative age, so warn
    ## (mirroring .warn_unmapped()) rather than mislabel it.
    orig <- icd_df$ager27
    bad <- unique(orig[!is.na(orig) & !orig %in% 1:27])
    if (length(bad) > 0L) {
        warning(sprintf(paste0(
            "convert_ager27(): %d value(s) outside the documented AGER27 domain ",
            "(1-27): %s."), length(bad), paste(sort(bad), collapse = ", ")),
            call. = FALSE)
    }

    df <- icd_df |>
        dplyr::mutate(ager27 = ifelse(ager27 == 27, NA, ager27),
               age = (findInterval(ager27, c(0, 7:23, 100)) - 1) * 5)

    if (remove_age27) {
        df <- dplyr::select(df, -ager27)
    }

    return(df)
}
