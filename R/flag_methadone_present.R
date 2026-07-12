#' Creates a column `methadone_present` if opioid death involved methadone
#'
#' This function flags all opioid deaths that involved methadone.
#'
#' @param processed_df MCOD dataframe already processed
#' @param year if NULL, will attempt to detect
#' @param keep_cols keep intermediate columns
#' @param opioid_deaths_only if `TRUE` (default) the flag fires only on opioid
#'   deaths (`opioid_death == 1`); if `FALSE`, it fires wherever the methadone
#'   code appears (including contributory-only records) and the caller is
#'   expected to `filter(opioid_death == 1)` themselves.
#'
#' @return a new dataframe with 1 additional column
#' @importFrom dplyr mutate case_when select any_of
#' @importFrom tibble has_name
#' @export
#' @examples
#' df <- data.frame(year = 2019, ucod = "X42", f_records_all = "T403")
#' df |>
#'     flag_opioid_deaths(year = 2019) |>
#'     flag_methadone_present(year = 2019)
flag_methadone_present <- function(processed_df, year = NULL,
                                   keep_cols = FALSE,
                                   opioid_deaths_only = TRUE) {
    ## Extract year
    if (is.null(year)) {
        year <- .extract_year(processed_df)
    }

    original_cols <- names(processed_df)
    if (!(tibble::has_name(processed_df, "f_records_all"))) {
        processed_df <- processed_df |>
            unite_records(year = year)
        }

    gate <- .opioid_gate(processed_df, opioid_deaths_only,
                         "flag_methadone_present")

    if (.dispatch_era(year) == "icd9") {
        new_df <- processed_df |>
            dplyr::mutate(methadone_present =
                       dplyr::case_when(grepl(ucod, pattern = .opioid_subtype_regex("methadone", "icd9")) &
                                     !!gate ~ 1,
                                 grepl(f_records_all, pattern = .opioid_subtype_regex("methadone", "icd9")) &
                                     !!gate ~ 1,
                                 TRUE ~ 0))
    } else {
        new_df <- processed_df |>
            dplyr::mutate(methadone_present =
                       dplyr::case_when(grepl(f_records_all, pattern = .opioid_subtype_regex("methadone", "icd10")) &
                                     !!gate ~ 1,
                                 TRUE ~ 0))
    }

    ## Drop all intermediate columns?
    if (!keep_cols) {
        new_df <- suppressMessages(suppressWarnings(
            dplyr::select(new_df,
                          dplyr::any_of(c(original_cols, "methadone_present")))
        ))
    }

    return(new_df)
}
