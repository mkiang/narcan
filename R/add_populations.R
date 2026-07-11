#' Given a dataframe with year, age, sex, and race, returns population estimate
#'
#' Uses the internal narcan::pop_est dataset to return yearly population
#' estimates by age, sex, and race. See narcan::pop_est for columns and
#' possible values of each matching variable
#'
#' @note Denominators are bridged-race population estimates, which NCHS
#'   discontinued after Vintage 2020. Rates for data year 2021 onward require
#'   single-race population estimates (and the 2003 numeric->M/F `sex` recode must
#'   be reconciled). Do not divide single-race death counts (see remap_race() for
#'   2022+) by these bridged-race denominators. Single-race denominator support is
#'   a separate, future work item.
#'
#' @param df MCOD dataframe
#' @param by_vars variables to match on
#'
#' @return dataframe
#' @importFrom dplyr left_join select
#' @export
#' @examples
#' df <- data.frame(year = 2019, age = 25, sex = "male", race = "white")
#' add_pop_counts(df)
add_pop_counts <- function(df, by_vars = c("year", "age", "sex", "race")) {
    .check_mcod_df(df, need = by_vars, fn = "add_pop_counts")
    if ("pop" %in% names(df)) {
        stop("add_pop_counts(): `df` already has a `pop` column; remove or ",
             "rename it before joining population estimates.", call. = FALSE)
    }
    x <- left_join(df, select(narcan::pop_est, -age_cat), by = by_vars)
    unmatched <- is.na(x$pop)
    if (any(unmatched)) {
        combos <- unique(x[unmatched, by_vars, drop = FALSE])
        warning(sprintf(
            paste0("add_pop_counts(): %d row(s) had no matching population in ",
                   "narcan::pop_est (pop = NA), spanning %d distinct %s ",
                   "combination(s). Check that these values use pop_est's ",
                   "coding -- e.g. categorize_race()'s finer bridged categories ",
                   "(american_indian/chinese/japanese/hawaiian/filipino) have ",
                   "no rows in pop_est."),
            sum(unmatched), nrow(combos), paste(by_vars, collapse = "/")),
            call. = FALSE)
    }
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
#' @examples
#' df <- data.frame(age = c(0, 5, 25, 85))
#' add_std_pop(df)
add_std_pop <- function(df, std_cat = "s204", by_vars = "age") {
    .check_mcod_df(df, need = by_vars, fn = "add_std_pop")
    clash <- intersect(c("pop_std", "unit_w"), names(df))
    if (length(clash) > 0L) {
        stop(sprintf(
            "add_std_pop(): `df` already has column(s) %s; remove or rename before joining.",
            paste0("`", clash, "`", collapse = ", ")), call. = FALSE)
    }
    std_pop_df <- narcan::std_pops |>
        filter(standard == std_cat) |>
        select(pop_std, age) |>
        mutate(unit_w = pop_std / sum(pop_std))

    x <- left_join(df, std_pop_df, by = by_vars)
    return(x)
}
