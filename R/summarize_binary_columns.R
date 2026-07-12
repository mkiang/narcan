#' Summarizes all flagged (e.g., 0/1) MCOD columns
#'
#' To use this, you must remove all non-grouping, non-binary variables.
#'
#' @details Rows are grouped by `year`, `age`, and `age_cat` (plus any bare
#'   variables passed in `...`); all three columns are required. The function
#'   stops early with a clear message if any is missing, rather than failing with
#'   a cryptic dplyr error deep inside `group_by()`. Create `age_cat` with
#'   [categorize_age_5()]. Every remaining non-grouping column is summed as a 0/1
#'   flag.
#'
#' @param df a dataframe with binary flag columns to indicate type of death,
#'   plus the required grouping columns `year`, `age`, and `age_cat`
#' @param ... grouping variables (in addition to year, age, and age_cat)
#'
#' @return dataframe
#' @importFrom dplyr group_by group_vars summarize across everything left_join n
#' @importFrom rlang .data
#' @export
#' @examples
#' df <- data.frame(
#'     year = c(2019, 2019),
#'     age = c(25, 25),
#'     age_cat = c("20-24", "20-24"),
#'     opioid_death = c(1, 0),
#'     drug_death = c(1, 1)
#' )
#' summarize_binary_columns(df)
summarize_binary_columns <- function(df, ...) {
    ## Guard: grouping by year/age/age_cat hard-requires all three columns.
    ## Naming the missing one here avoids a cryptic dplyr error inside group_by().
    required <- c("year", "age", "age_cat")
    missing_cols <- setdiff(required, names(df))
    if (length(missing_cols) > 0L) {
        stop("summarize_binary_columns() groups by `year`, `age`, and ",
             "`age_cat`; missing required column(s): ",
             paste(missing_cols, collapse = ", "),
             ". (Create `age_cat` with categorize_age_5().)", call. = FALSE)
    }

    ## Takes a tibble that has already been flagged with opioid columns and
    ## summarizes them over year and age (plus any extra bare grouping
    ## variables passed in ...).
    df <- df |>
        dplyr::group_by(.data$year, .data$age, .data$age_cat) |>
        dplyr::group_by(..., .add = TRUE)

    ## Guard: everything() sums every non-grouping column as if it were a 0/1
    ## flag. Warn on any column that is not binary (would be summed as a total)
    ## and on any NA (summed with na.rm = TRUE below, so a flag total can then
    ## differ from `deaths = n()`).
    sum_cols <- setdiff(names(df), dplyr::group_vars(df))
    not_binary <- sum_cols[vapply(
        sum_cols, function(cc) !all(df[[cc]] %in% c(0, 1, NA)), logical(1)
    )]
    if (length(not_binary) > 0) {
        warning("Non-binary column(s) summed as if they were 0/1 flags: ",
                paste(not_binary, collapse = ", "),
                ". Remove non-flag columns before summarizing.", call. = FALSE)
    }
    if (any(vapply(sum_cols, function(cc) anyNA(df[[cc]]), logical(1)))) {
        warning("NA values in flag column(s); summed with na.rm = TRUE, so flag ",
                "totals may not equal `deaths`.", call. = FALSE)
    }

    o_df <- dplyr::summarize(df, dplyr::across(dplyr::everything(), \(x) sum(x, na.rm = TRUE)))

    n_df <- df |>
        dplyr::summarize(deaths = dplyr::n()) |>
        dplyr::left_join(o_df, by = dplyr::group_vars(df))

    n_df
}
