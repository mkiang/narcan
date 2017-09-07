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
#' @importFrom dplyr mutate_at starts_with vars
#' @export
clean_icd9_data <- function(icd9_df) {
    ## Clean up names
    df <- rename_ni_flag(icd9_df)

    ## Fix 3-character codes in UCOD
    df <- mutate_at(df, vars(ucod), pad_3char_codes)

    ## Add prefix to UCOD
    df <- mutate_at(df, vars(ucod), prefix_e_to_ucod)

    ## Remove fifth char from record_
    df <- mutate_at(df, vars(starts_with("record_")), trim_5char_record)

    ## Fix traililng white space in record_
    df <- mutate_at(df, vars(starts_with("record_")), trim_trailing_whitespace)

    ## Pad 3 char record_ codes ----
    df <- mutate_at(df, vars(starts_with("record_")), pad_3char_codes)

    return(df)
}
