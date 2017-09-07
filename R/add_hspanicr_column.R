#' Add an NA hspanicr column if one doesn't exist
#'
#' Hispanic origin was not recorded until 1989. In order to keep all dataframes
#' comformable, add an NA column named hspanicr if one does not exist.
#'
#' @param icd_df an MCOD dataframe)
#'
#' @return dataframe
#' @importFrom tibble add_column
#' @export
add_hspanicr_column <- function(icd_df) {
    ## Hispanic wasn't recorded until 1989, so just make a NA hspanicr column
    ## for years that don't have one.
    if (!("hspanicr" %in% names(icd_df))) {
        icd_df <- icd_df %>%
            add_column(hspanicr = NA)
    }
    return(icd_df)
}
