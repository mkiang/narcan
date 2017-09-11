#' Given a dataframe with year, age, sex, and race, returns population estimate
#'
#' Uses the internal narcan::pop_est dataset to return yearly population
#' estimates by age, sex, and race. See narcan::pop_est for columns and
#' possible values of each matching variable
#'
#' @param df MCOD dataframe
#' @param by_vars variables to match on
#'
#' @return dataframe
#' @importFrom dplyr left_join select
#' @export
add_pop_counts <- function(df, by_vars = c("year", "age", "sex", "race")) {
    x <- left_join(df, select(narcan::pop_est, -age_cat), by = by_vars)
    return(x)
}


#' Given a dataframe with age, returns a standard population
#'
#' Returns the US 2000 population by default, by any population from the
#' narcan::std_pop$std_cat column is valid.
#'
#' @param df dataframe with age column (in 5-year bins)
#' @param std_cat standard population to use (default: US 2000 standard pop)
#' @param by_vars variables to merge on
#'
#' @return dataframe
#' @importFrom dplyr filter select mutate left_join
#' @export
add_std_pop <- function(df, std_cat = "s204", by_vars = "age") {
    std_pop_df <- narcan::std_pops %>%
        filter(standard == std_cat) %>%
        select(pop_std, age) %>%
        mutate(unit_w = pop_std / sum(pop_std))

    x <- left_join(df, std_pop_df, by = by_vars)
    return(x)
}
