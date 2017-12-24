#' Flag opioid deaths according to ISW7 rules
#'
#' Given an MCOD dataframe, will apply ISW7 rules to flag opioid deaths for
#' both ICD9 and ICD10 codes. Expects you to run unite_records() first. If you
#' don't, it will do so, but will remove that columns by default. Change
#' keep_cols = TRUE to keep it.
#'
#' @param processed_df processed dataframe
#' @param year if NULL, will attempt to detect
#' @param keep_cols keep intermediate columns (if they were created)
#'
#' @return new dataframe with an opioid_death column
#' @importFrom dplyr select
#' @importFrom tibble has_name
#' @export
flag_opioid_deaths <- function(processed_df, year = NULL, keep_cols = FALSE) {
    ## Make a new column called `opioid_death` that is:
    ##  - true for ICD9 if any opioid code is in any UCOD or record field
    ##  - true for ICD10 if contains specified UCOD **and** at least
    ##      one specified T code.

    ## Extract year
    if (is.null(year)) {
        year <- .extract_year(processed_df)
    }

    ## Check if already preprocessed with necessary columns
    intermediate_cols_made <- FALSE
    if (!(tibble::has_name(processed_df, "f_records_all"))) {
        processed_df <- processed_df %>% unite_records(year = year)
        intermediate_cols_made <- TRUE
    }

    ## Flag opioid deaths according to ICD definition
    if (year >= 1979 & year <= 1998) {
        df <- processed_df %>%
            mutate(opioid_death =
                       (grepl(.regex_opioid_icd9(), ucod) |
                            grepl(.regex_opioid_icd9(n_codes = TRUE),
                                  f_records_all)) + 0)
    } else {
        df <- processed_df %>%
            mutate(opioid_death =
                       (grepl(.regex_opioid_icd10(ucod_codes = TRUE), ucod) &
                            grepl(.regex_opioid_icd10(t_codes = TRUE),
                                  f_records_all)) + 0)
    }

    ## Check to make sure both that the option to keep intermediate columns
    ## if TRUE and also that we made them in the first place so we aren't
    ## deleting columns the user specifically made.
    if (keep_cols & intermediate_cols_made) {
        df <- dplyr::select(df, -f_records_all)
    }

    return(df)
}
