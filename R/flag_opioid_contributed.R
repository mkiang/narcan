#' Flag non-opioid deaths that involved opioids
#'
#' Given an MCOD dataframe, will search through contributory causes for
#' opioid related codes, but will only flag rows for which the underlying
#' cause is **NOT** an opioid-related death.
#'
#' For ICD-9-era data (pre-1999) this flag is undefined: narcan's ICD-9
#' opioid-death rule fires on any opioid code in any field, so an opioid recorded
#' only in a contributory cause already makes the death an opioid death -- there
#' is no "opioid contributed but not the underlying opioid death" subset to flag.
#' On ICD-9 input the function therefore warns and returns `NA` rather than a
#' misleading 0/1. (For ICD-10 the underlying-cause and contributory sets are
#' disjoint, so the flag is well defined.)
#'
#' @param processed_df processed dataframe
#' @param year if NULL, will attempt to detect
#'
#' @return new dataframe with an `opioid_contributed` column (`NA` for ICD-9-era
#'   data; see the note above)
#' @export
#' @examples
#' df <- data.frame(year = 2019, ucod = "I250", f_records_all = "T401")
#' flag_opioid_contributed(df, year = 2019)
flag_opioid_contributed <- function(processed_df, year = NULL) {
    ## Make a new column called `opioid_death` that is:
    ##  - true for ICD9 if any opioid code is in any UCOD or record field
    ##  - true for ICD10 if contains specified UCOD **and** at least
    ##      one specified T code.

    ## Extract year
    if (is.null(year)) {
        year <- .extract_year(processed_df)
    }

    if (.dispatch_era(year) == "icd9") {
        ## ICD-9 opioid_death fires on any opioid code in any field, so the
        ## "contributed but not the underlying opioid death" subset is empty --
        ## every row this would flag is already an opioid death. Return NA (not a
        ## misleading, always-redundant 0/1) and say so once.
        warning("flag_opioid_contributed() is not defined for ICD-9-era data: ",
                "the ICD-9 opioid-death rule fires on any opioid code in any ",
                "field, so an opioid in a contributory cause already makes the ",
                "death an opioid death. Returning NA for `opioid_contributed`.",
                call. = FALSE)
        df <- processed_df |>
            dplyr::mutate(opioid_contributed = NA_real_)
    } else {
        df <- processed_df |>
            dplyr::mutate(opioid_contributed =
                       (!(grepl(.regex_opioid_icd10(ucod_codes = TRUE),
                                ucod)) &
                            grepl(.regex_opioid_icd10(t_codes = TRUE),
                                  f_records_all)) + 0)
    }

    return(df)
}
