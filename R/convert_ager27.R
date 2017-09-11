#' Converts the age27 variable in MCOD data to 5-year age groups
#'
#' @param icd_df an MCOD dataframe with age27 as a column
#' @param remove_age27 once a new column is created, remove the old age27
#'
#' @return dataframe
#' @importFrom dplyr mutate select
#' @export
convert_ager27 <- function(icd_df, remove_age27 = TRUE) {
    df <- icd_df %>%
        mutate(ager27 = ifelse(ager27 == 27, NA, ager27),
               age = (findInterval(ager27, c(0, 7:23, 100)) - 1) * 5)

    if (remove_age27) {
        df <- select(df, -ager27)
    }

    return(df)
}
