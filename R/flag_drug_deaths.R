#' Flag drug deaths according to ISW7 rules
#'
#' Given an MCOD dataframe, will apply ISW7 rules to flag drug deaths for
#' both ICD9 and ICD10 codes.
#'
#' @param processed_df processed dataframe
#' @param year if NULL, will attempt to detect
#' @param keep_cols keep intermediate columns
#'
#' @return new dataframe with a drug_death column
#' @importFrom dplyr select one_of "%>%" mutate
#' @importFrom tibble has_name
#' @export
flag_drug_deaths <- function(processed_df, year = NULL, keep_cols = FALSE) {
    ## Make a new column called `drug_death` that is true for ICD9 if any poison
    ## code is in any record field and true for ICD10 if contains specified
    ## UCOD **and** at least one specified T code.
    ##
    ## Returns a new tibble.

    ## Extract year
    if (is.null(year)) {
        year <- .extract_year(processed_df)
    }

    ## Check if already preprocessed with necessary columns
    original_cols <- names(processed_df)
    if (!(tibble::has_name(processed_df, "f_records_all"))) {
        processed_df <- processed_df %>%
            unite_records(year = year)
    }

    if (year >= 1979 & year <= 1998) {
        df <- processed_df %>%
            dplyr::mutate(drug_death = (
                grepl(.regex_drug_icd9(), ucod) |
                    grepl(.regex_drug_icd9(n_codes = TRUE),
                          f_records_all)) + 0)
    } else {
        df <- processed_df %>%
            dplyr::mutate(drug_death = (
                grepl(.regex_drug_icd10(ucod_codes = TRUE), ucod) &
                    grepl(.regex_drug_icd10(t_codes = TRUE),
                          f_records_all)) + 0)
    }

    ## Drop all intermediate columns?
    if (!keep_cols) {
        df <- suppressMessages(suppressWarnings(
            dplyr::select(df, one_of(c(original_cols, "drug_death")))
        ))
    }


    return(df)
}
