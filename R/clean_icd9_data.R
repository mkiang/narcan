#' A wrapper function to perform basic cleaning of ICD-9 dataframes
#'
#' Across 1979-1998, MCOD data have minor inconsistencies. This wrapper
#' function renames nature of injury columns, pads UCOD codes with no
#' sub-codes, prefixes an E to external cause of injury codes and an N to
#' nature of injury codes, and trims unnecessary characters and whitespace.
#'
#' @param icd9_df an ICD-9 dataframe
#'
#' @return dataframe
#' @importFrom dplyr mutate across starts_with
#' @export
#' @examples
#' df <- data.frame(
#'     ucod = c("8001", "4321"),
#'     record_1 = c("8001", "4321"),
#'     rniflag_1 = c(0, 1)
#' )
#' clean_icd9_data(df)
clean_icd9_data <- function(icd9_df) {
    ## Clean up names
    df <- rename_ni_flag(icd9_df)

    ## Fix 3-character codes in UCOD, then add the E prefix to external causes
    df <- mutate(df, ucod = pad_3char_codes(ucod))
    df <- mutate(df, ucod = prefix_e_to_ucod(ucod))

    ## Remove fifth char, trim trailing whitespace, and pad 3-char record_ codes
    df <- mutate(df, across(starts_with("record_"), trim_5char_record))
    df <- mutate(df, across(starts_with("record_"), trim_trailing_whitespace))
    df <- mutate(df, across(starts_with("record_"), pad_3char_codes))

    return(df)
}
