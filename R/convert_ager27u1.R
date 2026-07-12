#' Converts the age27 variable in MCOD data to under-1, 1-4, then 5-year groups
#'
#' @details Expects `ager27` in its documented domain (codes 1-27, where 27 is
#'   "age not stated" and maps to `NA`). A non-`NA` value outside 1-27 triggers a
#'   warning, since it would otherwise fall through the recode and become `NA`.
#'
#'   NCHS Age Recode 27: codes 1-2 are deaths under 1 year (`Under 1 month`,
#'   `1 month - 11 months`) and map to `age = 0` (the `<1` bin); codes 3-6 are
#'   `1 year`, `2 years`, `3 years`, `4 years` (collectively `1-4 years`) and map
#'   to `age = 1`. Codes 7-26 use the same 5-year mapping as [convert_ager27()].
#'
#' @param icd_df an MCOD dataframe with age27 as a column
#' @param remove_age27 once a new column is created, remove the old age27
#'
#' @return dataframe
#' @importFrom dplyr mutate select case_when between
#' @export
#' @examples
#' df <- data.frame(ager27 = c(1, 3, 10, 27))
#' convert_ager27u1(df)
convert_ager27u1 <- function(icd_df, remove_age27 = TRUE) {
    ## Guard: AGER27 is documented to hold codes 1-27. A value outside 1:27 would
    ## fall through case_when() and silently become NA, so warn (mirroring
    ## .warn_unmapped()) rather than drop it.
    orig <- icd_df$ager27
    bad <- unique(orig[!is.na(orig) & !orig %in% 1:27])
    if (length(bad) > 0L) {
        warning(sprintf(paste0(
            "convert_ager27u1(): %d value(s) outside the documented AGER27 ",
            "domain (1-27): %s."), length(bad),
            paste(sort(bad), collapse = ", ")), call. = FALSE)
    }

    df <- icd_df |>
        dplyr::mutate(ager27 = ifelse(ager27 == 27, NA, ager27),
               age = dplyr::case_when(dplyr::between(ager27, 1, 2) ~ 0,
                               dplyr::between(ager27, 3, 6) ~ 1,
                               dplyr::between(ager27, 7, 22) ~ (ager27 - 6) * 5,
                               dplyr::between(ager27, 23, 26) ~ 85,
                               ager27 == 27 ~ NA_real_)
        )

    if (remove_age27) {
        df <- dplyr::select(df, -ager27)
    }

    return(df)
}
