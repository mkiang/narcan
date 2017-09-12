#' Flag suicide deaths (no accidental poisoning)
#'
#' TODO: Make this also work with ICD-9
#'
#' @param df processed MCOD dataframe
#'
#' @return new dataframe
#' @importFrom dplyr mutate
#' @export
flag_suicide_deaths <- function(df) {
    new_df <- df %>%
        mutate(suicide_death = grepl("U03|X[67]\\d{1}|X8[01234]|Y870",
                                   ucod) + 0)

    return(new_df)
}
