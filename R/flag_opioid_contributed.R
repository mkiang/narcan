#' Flag non-opioid deaths that involved opioids
#'
#' Given an MCOD dataframe, will search through contributory causes for
#' opioid related codes, but will only flag rows for which the underlying
#' cause is **NOT** an opioid-related death.
#'
#' NOTE: This function really doesn't make sense for ICD-9 years. Use with
#' caution.
#'
#' @param processed_df processed dataframe
#' @param year if NULL, will attempt to detect
#'
#' @return new dataframe with an opioid_contributed column
#' @export
flag_opioid_contributed <- function(processed_df, year = NULL) {
    ## Make a new column called `opioid_death` that is:
    ##  - true for ICD9 if any opioid code is in any UCOD or record field
    ##  - true for ICD10 if contains specified UCOD **and** at least
    ##      one specified T code.

    ## Extract year
    if (is.null(year)) {
        year <- .extract_year(processed_df)
    }

    if (year >= 1979 & year <= 1998) {
        df <- processed_df %>%
            mutate(opioid_contributed =
                       (!(grepl(.regex_opioid_icd9(), ucod)) &
                            grepl(.regex_opioid_icd9(n_codes = TRUE),
                                  f_records_all)) + 0)
    } else {
        df <- processed_df %>%
            mutate(opioid_contributed =
                       (!(grepl(.regex_opioid_icd10(ucod_codes = TRUE),
                                ucod)) &
                            grepl(.regex_opioid_icd10(t_codes = TRUE),
                                  f_records_all)) + 0)
    }

    return(df)
}
