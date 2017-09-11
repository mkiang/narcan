#' Creates a new column called heroin_present if opioid death involved heroin
#'
#' Heroin deaths were recorded in both ICD-9 and ICD-10 years. This creates
#' a new column to flag when that death involved heroin and was an opioid
#' death as defined by flag_opioid_death().
#'
#' @param processed_df MCOD dataframe already processed
#' @param year if NULL, will attempt to detect
#'
#' @return a new dataframe with 1 additional column
#' @importFrom dplyr mutate case_when
#' @export
flag_heroin_present <- function(processed_df, year = NULL) {
    ## Extract year
    if (is.null(year)) {
        year <- .extract_year(processed_df)
    }

    if (year >= 1979 & year <= 1998) {
        new_df <- processed_df %>%
            mutate(heroin_present =
                       case_when(grepl(ucod, pattern = "E8500") &
                                     opioid_death == 1 ~ 1,
                                 grepl(f_records_all, pattern = "E8500") &
                                     opioid_death == 1 ~ 1,
                                 TRUE ~ 0))
    } else {
        new_df <- processed_df %>%
            mutate(heroin_present =
                       case_when(grepl(f_records_all, pattern = "T401") &
                                     opioid_death == 1 ~ 1,
                                 TRUE ~ 0))
    }

    return(new_df)
}
