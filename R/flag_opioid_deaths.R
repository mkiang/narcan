#' Flag opioid deaths according to ISW7 rules
#'
#' Given an MCOD dataframe, will apply ISW7 rules to flag opioid deaths for
#' both ICD9 and ICD10 codes. Expects you to run unite_records() first. If you
#' don't, it will do so, but will remove that columns by default. Change
#' keep_cols = TRUE to keep it.
#'
#' @note "Any opioid" includes T40.6 ("other and unspecified narcotics"),
#'   following ISW7 and NCHS. Per the ISW7 (2012) Appendix B1 footnote, T40.6
#'   can capture non-opioids (e.g., cocaine) in some jurisdictions.
#'
#' @param processed_df processed dataframe
#' @param year if NULL, will attempt to detect
#' @param keep_cols keep intermediate columns
#'
#' @return new dataframe with a binary opioid_death column
#' @importFrom dplyr select any_of mutate
#' @importFrom tibble has_name
#' @export
#' @examples
#' df <- data.frame(year = 2019, ucod = "X42", f_records_all = "T401")
#' flag_opioid_deaths(df, year = 2019)
flag_opioid_deaths <- function(processed_df, year = NULL, keep_cols = FALSE) {
    ## Make a new column called `opioid_death` that is:
    ##  - true for ICD9 if any opioid code is in any UCOD or record field
    ##  - true for ICD10 if contains specified UCOD **and** at least
    ##      one specified T code.
    .check_mcod_df(processed_df, need = "ucod", fn = "flag_opioid_deaths")

    ## Extract year
    if (is.null(year)) {
        year <- .extract_year(processed_df)
    }

    ## Check if already preprocessed with necessary columns
    original_cols <- names(processed_df)
    if (!(tibble::has_name(processed_df, "f_records_all"))) {
        warning("Missing the column `f_records_all`. ",
                "Generating this column automatically.\n",
                "As a result, all `record_` columns will be dropped.\n",
                "See help(unite_records) for more information.")
        processed_df <- processed_df |>
            unite_records(year = year)
    }

    ## Flag opioid deaths according to ICD definition
    if (.dispatch_era(year) == "icd9") {
        new_df <- processed_df |>
            dplyr::mutate(opioid_death =
                       (grepl(.regex_opioid_icd9(), ucod) |
                            grepl(.regex_opioid_icd9(n_codes = TRUE),
                                  f_records_all)) + 0)
    } else {
        new_df <- processed_df |>
            dplyr::mutate(opioid_death =
                       (grepl(.regex_opioid_icd10(ucod_codes = TRUE), ucod) &
                            grepl(.regex_opioid_icd10(t_codes = TRUE),
                                  f_records_all)) + 0)
    }

    ## Drop all intermediate columns?
    if (!keep_cols) {
        new_df <- suppressMessages(suppressWarnings(
            dplyr::select(
                new_df, dplyr::any_of(c(original_cols, "opioid_death"))
                )
        ))
    }

    return(new_df)
}
