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
#' @importFrom dplyr mutate
#' @importFrom rlang :=
#' @export
calc_asrate_var <- function(df, new_name, death_col, pop_col = pop) {
    ## Returns the age-specific mortality rate of `death_col` and its
    ## Poisson-approximation variance in new columns `{new_name}_rate` and
    ## `{new_name}_var`. The rate cannot be reused inside the variance within a
    ## single mutate(), so the ratio is recomputed.
    .check_mcod_df(df, fn = "calc_asrate_var")

    df |>
        mutate(
            "{{ new_name }}_rate" := ({{ death_col }} / {{ pop_col }}) * 10^5,
            "{{ new_name }}_var" :=
                (({{ death_col }} / {{ pop_col }}) * 10^5)^2 / {{ death_col }}
        )
}
