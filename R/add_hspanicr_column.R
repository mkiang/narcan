#' Add an NA hspanicr column if one doesn't exist
#'
#' Hispanic origin was not recorded until 1989. In order to keep all dataframes
#' conformable, add an NA column named hspanicr if one does not exist.
#'
#' @param icd_df an MCOD dataframe)
#'
#' @return dataframe
#' @importFrom tibble add_column
#' @export
#' @examples
#' df <- data.frame(year = 2019, ucod = "X42")
#' add_hspanicr_column(df)
add_hspanicr_column <- function(icd_df) {
    ## Hispanic wasn't recorded until 1989, so just make a NA hspanicr column
    ## for years that don't have one.
    if (!("hspanicr" %in% names(icd_df))) {
        ## NA_real_, not a bare (logical) NA: the real hspanicr column is
        ## imported as readr type "n" (double; see .import_mcod_data()), so a
        ## logical NA here would make a synthesized pre-1989 column
        ## type-mismatch a real hspanicr column on bind_rows().
        icd_df <- icd_df |>
            tibble::add_column(hspanicr = NA_real_)
    }
    return(icd_df)
}
