#' Creates a column `other_natural_present` if opioid death involved opium
#'
#' Note that ICD9 years did not include an other_natural code.
#' We code it as 0 by default, but can be coded however specified in
#' missing_val parameter. This function flags all opioid deaths that involved
#' other natural/semi-synthetic opioids.
#'
#' @param processed_df MCOD dataframe already processed
#' @param year if NULL, will attempt to detect
#' @param missing_val value to indicate missing (i.e., code did not exist)
#'
#' @return a new dataframe with 1 additional column
#' @importFrom dplyr mutate case_when
#' @export
flag_other_natural_present <- function(processed_df, year = NULL,
                                       missing_val = 0) {
    ## Extract year
    if (is.null(year)) {
        year <- .extract_year(processed_df)
    }

    if (year >= 1979 & year <= 1998) {
        new_df <- processed_df %>%
            mutate(other_natural_present = missing_val)
    } else {
        new_df <- processed_df %>%
            mutate(other_natural_present =
                       case_when(grepl(f_records_all, pattern = "T402") &
                                     opioid_death == 1 ~ 1,
                                 TRUE ~ 0))
    }
    return(new_df)
}
