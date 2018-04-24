#' Creates a column `methadone_present` if opioid death involved methadone
#'
#' This function flags all opioid deaths that involved methadone.
#'
#' @param processed_df MCOD dataframe already processed
#' @param year if NULL, will attempt to detect
#' @param keep_cols keep intermediate columns
#'
#' @return a new dataframe with 1 additional column
#' @importFrom dplyr mutate case_when select "%>%" one_of
#' @importFrom tibble has_name
#' @export
flag_methadone_present <- function(processed_df, year = NULL,
                                   keep_cols = FALSE) {
    ## Extract year
    if (is.null(year)) {
        year <- .extract_year(processed_df)
    }

    original_cols <- names(processed_df)
    if (!(tibble::has_name(processed_df, "f_records_all"))) {
        processed_df <- processed_df %>%
            unite_records(year = year)
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

    ## Drop all intermediate columns?
    if (!keep_cols) {
        new_df <- suppressMessages(suppressWarnings(
            dplyr::select(new_df,
                          one_of(c(original_cols, "methadone_present")))
        ))
    }

    return(new_df)
}
