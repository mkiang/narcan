#' Flag all opioid deaths that were not from heroin
#'
#' NOTE: assumes flag_opioid_types() has already been run.
#'
#' @param processed_df MCOD dataframe with flag_opioid_types() columns
#'
#' @return dataframe
#' @importFrom dplyr case_when mutate
#' @export
flag_nonheroin <- function(processed_df) {
    ## Makes a new column to indicate a non-heroin opioid death.
    ## That is, 1 == opioid death by opioid other than heroin, 0 ==
    ## opioid death by heroin.

    new_df <- processed_df %>%
        mutate(nonheroin_present = case_when(
            num_opioids > 0 & heroin_present == 0 ~ 1,
            TRUE ~ 0))

    return(new_df)
}
