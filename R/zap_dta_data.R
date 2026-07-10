#' Clear Stata metadta from MCOD dta files
#'
#' The NBER MCOD dta files come with a variety of metadata not necessary for
#' use in R. This function clears all metadata as well as replacing NAN and
#' blanks ("") with NA.
#'
#' @param dta_df dataframe from imported dta (e.g., from haven::read_dta())
#'
#' @return dataframe
#' @importFrom haven zap_formats zap_labels zap_missing zap_empty
#' @importFrom dplyr mutate across where
#' @export
zap_dta_data <- function(dta_df) {
    ## ZAP EVERYTHING! Also change all NaNs to NA.
    dta_df <- dta_df |>
        dplyr::mutate(dplyr::across(dplyr::where(is.character),
                                    \(x) haven::zap_empty(x))) |>
        haven::zap_formats() |>
        haven::zap_labels() |>
        haven::zap_missing() |>
        dplyr::mutate(dplyr::across(dplyr::where(is.numeric),
                                    \(x) ifelse(is.nan(x), NA_real_, x)))

    ## Remove "" and replace with NA
    dta_df[dta_df == ""] <- NA

    return(dta_df)
}
