#' Creates a column `other_op_present` for deaths with other unspecified opioid
#'
#' This function flags all opioid deaths that involved other unspecified opioid
#'
#' @param processed_df MCOD dataframe already processed
#' @param year if NULL, will attempt to detect
#' @param opioid_deaths_only if `TRUE` (default) the flag fires only on opioid
#'   deaths (`opioid_death == 1`); if `FALSE`, it fires wherever the code appears
#'   (including contributory-only records) and the caller is expected to
#'   `filter(opioid_death == 1)` themselves.
#'
#' @return a new dataframe with 1 additional column
#' @importFrom dplyr mutate case_when
#' @export
#' @examples
#' df <- data.frame(year = 2019, ucod = "X42", f_records_all = "T406")
#' df |>
#'     flag_opioid_deaths(year = 2019) |>
#'     flag_other_op_present(year = 2019)
flag_other_op_present <- function(processed_df, year = NULL,
                                  opioid_deaths_only = TRUE) {
    ## Extract year
    if (is.null(year)) {
        year <- .extract_year(processed_df)
    }

    gate <- .opioid_gate(processed_df, opioid_deaths_only,
                         "flag_other_op_present")

    if (.dispatch_era(year) == "icd9") {
        new_df <- processed_df |>
            mutate(other_op_present =
                       case_when(grepl(ucod, pattern = "\\<E8502\\>") &
                                     !!gate ~ 1,
                                 grepl(f_records_all, pattern = "\\<E8502\\>") &
                                     !!gate ~ 1,
                                 TRUE ~ 0))
    } else {
        new_df <- processed_df |>
            mutate(other_op_present =
                       case_when(grepl(f_records_all, pattern = "\\<T406\\>") &
                                     !!gate ~ 1,
                                 TRUE ~ 0))
    }
    return(new_df)
}
