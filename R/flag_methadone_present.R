#' Creates a column `methadone_present` if opioid death involved methadone
#'
#' This function flags all opioid deaths that involved methadone.
#'
#' @param processed_df MCOD dataframe already processed
#' @param year if NULL, will attempt to detect
#'
#' @return a new dataframe with 1 additional column
#' @importFrom dplyr mutate case_when
#' @export
flag_methadone_present <- function(processed_df, year = NULL) {
    ## Extract year
    if (is.null(year)) {
        year <- .extract_year(processed_df)
    }

    if (year >= 1979 & year <= 1998) {
        new_df <- processed_df %>%
            mutate(methadone_present =
                       case_when(grepl(ucod, pattern = "E8501") &
                                     opioid_death == 1 ~ 1,
                                 grepl(f_records_all, pattern = "E8501") &
                                     opioid_death == 1 ~ 1,
                                 TRUE ~ 0))
    } else {
        new_df <- processed_df %>%
            mutate(methadone_present =
                       case_when(grepl(f_records_all, pattern = "T403") &
                                     opioid_death == 1 ~ 1,
                                 TRUE ~ 0))
    }
    return(new_df)
}
