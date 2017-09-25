#' Calculate age-specific rates and variance
#'
#' Given a bare (unquoted) column of counts and population, will return the
#' rate in 100,000 as well as the variance (using Poisson approximation).
#'
#' @param df processed MCOD dataframe
#' @param new_name bare prefix of the new column names (e.g., opioid)
#' @param death_col column of counts for numerator of rate
#' @param pop_col column of population for denominator of rate
#'
#' @return dataframe with two new columns
#' @importFrom rlang := !! !!! enquo quo quo_name
#' @export
calc_asrate_var <- function(df, new_name, death_col, pop_col = pop) {
    ## Returns the age-specific mortality rate of `death_col` and the variance
    ## in new columns `new_name_rate` and `new_name_var`.
    ## For some reason, cannot call !!rate_name inside of !!var_name so
    ## just repeat calculation.

    death_col <- enquo(death_col)
    pop_col   <- enquo(pop_col)
    new_name  <- enquo(new_name)
    rate_name <- paste0(quo_name(new_name), "_rate")
    var_name  <- paste0(quo_name(new_name), "_var")

    new_df <- df %>%
        mutate(
            !!rate_name := ((!!death_col) / (!!pop_col)) * 10^5,
            !!var_name  := ((((!!death_col) / (!!pop_col)) * 10^5)^2 /
                                (!!death_col))
        )

    return(new_df)
}
