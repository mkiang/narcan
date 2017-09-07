#' Flag drug deaths according to ISW7 rules
#'
#' Given an MCOD dataframe, will apply ISW7 rules to flag drug deaths for
#' both ICD9 and ICD10 codes.
#'
#' @param processed_df processed dataframe
#' @param year if NULL, will attempt to detect
#'
#' @return new dataframe with a drug_death column
#' @export
flag_drug_deaths <- function(processed_df, year = NULL) {
    ## Make a new column called `drug_death` that is true for ICD9 if any poison
    ## code is in any record field and true for ICD10 if contains specified
    ## UCOD **and** at least one specified T code.
    ##
    ## Returns a new tibble.

    ## Extract year
    if (is.null(year)) {
        year <- .extract_year(processed_df)
    }

    if (year >= 1979 & year <= 1998) {
        df <- processed_df %>%
            mutate(drug_death = (
                grepl(.regex_drug_icd9(), ucod) |
                    grepl(.regex_drug_icd9(n_codes = TRUE),
                          f_records_all)) + 0)
    } else {
        df <- processed_df %>%
            mutate(drug_death = (
                grepl(.regex_drug_icd10(ucod_codes = TRUE), ucod) &
                    grepl(.regex_drug_icd10(t_codes = TRUE),
                          f_records_all)) + 0)
    }

    return(df)
}
