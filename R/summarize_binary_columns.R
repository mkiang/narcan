#' Summarizes all flagged (e.g., 0/1) MCOD columns
#'
#' To use this, you must remove all non-grouping, non-binary variables.
#'
#' @param df a dataframe with binary flag columns to indicate type of death
#' @param ... grouping variables (in addition to year and age)
#'
#' @return dataframe
#' @importFrom dplyr group_by group_vars summarize across everything left_join n
#' @importFrom rlang quos !!!
#' @export
summarize_binary_columns <- function(df, ...) {
    ## Takes a tibble that has already been flagged with opioid columns and
    ## summarizes them over age and year and whatever other bare (unquoted)
    ## variable is given in the ...
    add_groups <- quos(...)
    df <- df %>%
        group_by(year, age, age_cat) %>%
        group_by(!!!add_groups, .add = TRUE)

    o_df <- summarize(df, across(everything(), sum))

    n_df <- df %>%
        summarize(deaths = n()) %>%
        left_join(o_df, by = group_vars(df))

    return(n_df)
}
