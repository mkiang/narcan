#' Add a binary Hispanic-origin column from hspanicr
#'
#' Adds a \code{hispanic_origin} column (\code{"hispanic"} / \code{"non_hispanic"}
#' / \code{"unknown"} / \code{NA}) derived from \code{hspanicr} and the data year,
#' so a death frame can be joined to Hispanic-stratified population denominators
#' via \code{\link{add_pop_counts}}. This is the population-join counterpart of
#' \code{\link{add_hspanicr_column}} (which backfills the raw \code{hspanicr}
#' field): Hispanic origin is ragged across years -- absent before 1989, reserved
#' in 2021, and recoded from 9 to 14 categories in 2022 -- so, like
#' \code{add_hspanicr_column()}, this reads the canonical year and tolerates a
#' missing/NA \code{hspanicr} (yielding \code{NA} origin for those rows).
#'
#' Year is read per row from \code{year} (1996+) or, failing that, the two-digit
#' \code{datayear} (1979-1995, normalized to four digits), so a multi-year frame
#' (e.g. \code{bind_rows()} of several data years) is labeled correctly row by
#' row. It errors if neither column is present.
#'
#' @param df an MCOD dataframe with \code{hspanicr} (or none, treated as NA) and a
#'   \code{year} or \code{datayear} column.
#'
#' @return \code{df} with an added \code{hispanic_origin} character column.
#' @seealso \code{\link{categorize_hispanic_origin}} (the vectorized recode);
#'   \code{\link{add_hspanicr_column}} (backfills the raw \code{hspanicr} field);
#'   \code{\link{add_pop_counts}} for the Hispanic-stratified population join.
#' @export
#'
#' @examples
#' df <- data.frame(year = 2019, hspanicr = c(1, 6, 9))
#' add_hispanic_origin(df)
add_hispanic_origin <- function(df) {
    .check_mcod_df(df, need = character(), fn = "add_hispanic_origin")
    if (!is.data.frame(df)) {
        return(df)
    }
    if ("hispanic_origin" %in% names(df)) {
        stop("add_hispanic_origin(): `df` already has a `hispanic_origin` ",
             "column; remove or rename it before adding one.", call. = FALSE)
    }

    ## Per-row year (vectorized): `year` (1996+) then two-digit `datayear`
    ## (1979-1995), normalized +1900 the way .extract_year() does -- but WITHOUT
    ## its single-year restriction, since a multi-year frame is the point.
    if ("year" %in% names(df)) {
        yr <- df[["year"]]
    } else if ("datayear" %in% names(df)) {
        yr <- df[["datayear"]]
    } else {
        stop("add_hispanic_origin(): no `year` or `datayear` column found; ",
             "`hispanic_origin` is year-dependent (the hspanicr scheme changed ",
             "in 2021/2022), so a year is required.", call. = FALSE)
    }
    yr <- suppressWarnings(as.numeric(as.character(yr)))
    two_digit <- !is.na(yr) & yr < 100
    yr[two_digit] <- yr[two_digit] + 1900

    ## Tolerate a missing hspanicr (pre-1989 frames have none) as NA origin,
    ## mirroring add_hspanicr_column()'s NA backfill.
    hsp <- if ("hspanicr" %in% names(df)) df[["hspanicr"]] else rep(NA_real_, nrow(df))

    df[["hispanic_origin"]] <- categorize_hispanic_origin(hsp, year = yr)
    df
}
