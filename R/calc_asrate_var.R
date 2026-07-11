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
#' @importFrom dplyr mutate pull
#' @importFrom rlang :=
#' @export
#' @examples
#' df <- data.frame(deaths = c(10, 20), pop = c(1e5, 2e5))
#' calc_asrate_var(df, opioid, deaths)
calc_asrate_var <- function(df, new_name, death_col, pop_col = pop) {
    ## Returns the age-specific mortality rate of `death_col` and its
    ## Poisson-approximation variance in new columns `{new_name}_rate` and
    ## `{new_name}_var`. The variance is written as deaths * (1e5/pop)^2 rather
    ## than rate^2/deaths: the two are algebraically identical for deaths > 0 but
    ## the rearranged form yields 0 (not 0/0 = NaN) for a zero-death cell, which
    ## are ubiquitous in stratified data.
    .check_mcod_df(df, fn = "calc_asrate_var")

    ## Value-neutral diagnostic: a pop == 0 cell yields an Inf/NaN rate. These are
    ## legitimate in fine strata (e.g. single-race county cells with no residents
    ## of a race), so warn rather than error and leave the arithmetic unchanged.
    pv <- tryCatch(dplyr::pull(df, {{ pop_col }}), error = function(e) NULL)
    if (!is.null(pv) && any(pv == 0, na.rm = TRUE)) {
        warning(sprintf(paste0(
            "calc_asrate_var(): %d cell(s) have pop == 0, so their rate is ",
            "Inf/NaN. Aggregate ages/geographies for a defined rate (single-race ",
            "county cells can be legitimately zero)."),
            sum(pv == 0, na.rm = TRUE)), call. = FALSE)
    }

    df |>
        dplyr::mutate(
            "{{ new_name }}_rate" := ({{ death_col }} / {{ pop_col }}) * 10^5,
            "{{ new_name }}_var" := {{ death_col }} * (10^5 / {{ pop_col }})^2
        )
}
