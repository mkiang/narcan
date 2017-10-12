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
#' @importFrom dplyr mutate_if
#' @export
zap_dta_data <- function(dta_df) {
    ## ZAP EVERYTHING! Also change all NaNs to NA.
    dta_df <- dta_df %>%
        dplyr::mutate_if(is.character, funs(haven::zap_empty(.))) %>%
        haven::zap_formats(.) %>%
        haven::zap_labels(.) %>%
        haven::zap_missing(.) %>%
        dplyr::mutate_if(is.numeric, funs(ifelse(is.nan(.), NA_real_, .)))

    ## Remove "" and replace with NA
    dta_df[dta_df == ""] <- NA

    return(dta_df)
}
