#' Run the canonical MCOD flagging pipeline
#'
#' Convenience wrapper that runs the standard raw-MCOD-to-flags chain in one
#' call: unite the record columns, then flag drug deaths, opioid deaths, opioid
#' types, and overdose intent. It is purely additive -- each step is the existing
#' exported function, run in the canonical order with the data year resolved once.
#'
#' @param df an MCOD data frame (a single data year)
#' @param year data year; if `NULL`, extracted from `df`
#' @param clean_icd9 if `TRUE`, also run [clean_icd9_data()] on ICD-9-era data
#'   (1979-1998) before uniting records. Usually unnecessary: [unite_records()]
#'   auto-cleans raw ICD-9 data, and [clean_icd9_data()] is idempotent (a no-op on
#'   already-clean data). It never runs on ICD-10 data regardless of this flag.
#'   Default `FALSE`.
#' @param types if `TRUE` (default), also run [flag_opioid_types()]
#' @param intent if `TRUE` (default), also run [flag_od_intent()]
#' @param opioid_deaths_only forwarded to [flag_opioid_types()] (see its help)
#'
#' @return the input data frame with the flag columns added
#' @export
#' @examples
#' df <- data.frame(year = 2019, ucod = "X42", f_records_all = "T401 T404")
#' flag_all_deaths(df, year = 2019)
flag_all_deaths <- function(df, year = NULL, clean_icd9 = FALSE,
                            types = TRUE, intent = TRUE,
                            opioid_deaths_only = TRUE) {
    .check_mcod_df(df, need = "ucod", fn = "flag_all_deaths")

    if (is.null(year)) {
        year <- .extract_year(df)
    }

    if (clean_icd9 && .dispatch_era(year) == "icd9") {
        df <- clean_icd9_data(df)
    }

    if (!("f_records_all" %in% names(df))) {
        df <- unite_records(df, year = year)
    }

    out <- df |>
        flag_drug_deaths(year = year) |>
        flag_opioid_deaths(year = year)

    if (types) {
        out <- flag_opioid_types(out, year = year,
                                 opioid_deaths_only = opioid_deaths_only)
    }
    if (intent) {
        out <- flag_od_intent(out, year = year)
    }

    out
}
