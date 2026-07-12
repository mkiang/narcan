#' Creates a new column called heroin_present if opioid death involved heroin
#'
#' Heroin deaths were recorded in both ICD-9 and ICD-10 years. This creates
#' a new column to flag when that death involved heroin and was an opioid
#' death as defined by flag_opioid_death().
#'
#' @param processed_df MCOD dataframe already processed
#' @param year if NULL, will attempt to detect
#' @param keep_cols keep intermediate columns
#' @param opioid_deaths_only if `TRUE` (default) the flag fires only on opioid
#'   deaths (`opioid_death == 1`); if `FALSE`, it fires wherever the heroin code
#'   appears (including contributory-only records) and the caller is expected to
#'   `filter(opioid_death == 1)` themselves.
#'
#' @return a new dataframe with a binary heroin_present column
#' @importFrom dplyr select any_of mutate
#' @importFrom tibble has_name
#' @export
#' @examples
#' df <- data.frame(year = 2019, ucod = "X42", f_records_all = "T401 T400")
#' flag_heroin_present(df, year = 2019)
flag_heroin_present <- function(processed_df, year = NULL, keep_cols = FALSE,
                                opioid_deaths_only = TRUE) {
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

    if (opioid_deaths_only &&
        !(tibble::has_name(processed_df, "opioid_death"))) {
        processed_df <- processed_df |>
            flag_opioid_deaths(year = year)
    }

    gate <- .opioid_gate(processed_df, opioid_deaths_only, "flag_heroin_present")

    if (.dispatch_era(year) == "icd9") {
        new_df <- processed_df |>
            dplyr::mutate(heroin_present =
                              dplyr::case_when(
                                  grepl(ucod, pattern = .opioid_subtype_regex("heroin", "icd9")) &
                                      !!gate ~ 1,
                                  grepl(f_records_all, pattern = .opioid_subtype_regex("heroin", "icd9")) &
                                      !!gate ~ 1,
                                  TRUE ~ 0))
    } else {
        new_df <- processed_df |>
            dplyr::mutate(heroin_present =
                              dplyr::case_when(
                                  grepl(f_records_all, pattern = .opioid_subtype_regex("heroin", "icd10")) &
                                      !!gate ~ 1,
                                  TRUE ~ 0))
    }

    ## Drop all intermediate columns?
    if (!keep_cols) {
        new_df <- suppressMessages(suppressWarnings(
            dplyr::select(
                new_df, dplyr::any_of(c(original_cols, "heroin_present"))
                )
        ))
    }

    return(new_df)
}
