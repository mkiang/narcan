#' Creates a column called `other_synth_present`
#'
#' Note that ICD9 years did not include an other synthetic opioid code.
#' We code it as 0 by default, but can be coded however specified in
#' missing_val parameter.
#' This function flags all opioid deaths that involved other synthetic opioid.
#'
#' @param processed_df MCOD dataframe already processed
#' @param year if NULL, will attempt to detect
#' @param missing_val value to indicate missing (i.e., code did not exist)
#' @param opioid_deaths_only if `TRUE` (default) the flag fires only on opioid
#'   deaths (`opioid_death == 1`); if `FALSE`, it fires wherever the code appears
#'   (including contributory-only records) and the caller is expected to
#'   `filter(opioid_death == 1)` themselves.
#'
#' @return a new dataframe with 1 additional column
#' @importFrom dplyr mutate case_when
#' @export
#' @examples
#' df <- data.frame(year = 2019, ucod = "X42", f_records_all = "T404")
#' df |>
#'     flag_opioid_deaths(year = 2019) |>
#'     flag_other_synth_present(year = 2019)
flag_other_synth_present <- function(processed_df, year = NULL, missing_val = 0,
                                     opioid_deaths_only = TRUE) {
    ## Extract year
    if (is.null(year)) {
        year <- .extract_year(processed_df)
    }

    if (.dispatch_era(year) == "icd9") {
        new_df <- processed_df |>
            dplyr::mutate(other_synth_present = missing_val)
    } else {
        gate <- .opioid_gate(processed_df, opioid_deaths_only,
                             "flag_other_synth_present")
        new_df <- processed_df |>
            dplyr::mutate(other_synth_present =
                       dplyr::case_when(grepl(f_records_all, pattern = "\\<T404\\>") &
                                     !!gate ~ 1,
                                 TRUE ~ 0))
    }

    return(new_df)
}
