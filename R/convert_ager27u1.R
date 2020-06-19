#' Converts the age27 variable in MCOD data to under-1, 1-4, then 5-year groups
#'
#' @param icd_df an MCOD dataframe with age27 as a column
#' @param remove_age27 once a new column is created, remove the old age27
#'
#' @return dataframe
#' @importFrom dplyr mutate select case_when
#' @export
convert_ager27u1 <- function(icd_df, remove_age27 = TRUE) {
    df <- icd_df %>%
        mutate(ager27 = ifelse(ager27 == 27, NA, ager27),
               age = case_when(between(ager27, 1, 2) ~ 0,
                               between(ager27, 3, 6) ~ 1,
                               between(ager27, 7, 22) ~ (ager27 - 6) * 5,
                               between(ager27, 23, 26) ~ 85,
                               ager27 == 27 ~ NA_real_)
        )

    if (remove_age27) {
        df <- select(df, -ager27)
    }

    return(df)
}
