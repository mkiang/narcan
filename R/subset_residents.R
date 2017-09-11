#' Subset to US residents
#'
#' @param df an MCOD dataframe
#' @param drop_col drop the `restatus` column after subsetting (default: TRUE)
#'
#' @return dataframe
#' @importFrom dplyr filter select
#' @export
subset_residents <- function(df, drop_col = TRUE) {
    new_df <- dplyr::filter(df, restatus %in% 1:3)
    if (drop_col) {
        new_df <- dplyr::select(new_df, -restatus)
    }
    return(new_df)
}
