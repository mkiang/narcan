#' Remap the raw NCHS detail-age field to age in completed years
#'
#' The NCHS "detail age" field (`age`) is unit-coded, and its encoding changed at
#' data year 2003: 1979-2002 use a 3-digit code, 2003 onward a 4-digit code. In
#' both eras a leading digit gives the unit (years, months, weeks, days, hours,
#' minutes, or "not stated"). This dispatches on the data year and returns age in
#' completed years in a new `age_years` column: sub-year ages (months/weeks/days/
#' hours/minutes) collapse to `0`, and not-stated ages become `NA`.
#'
#' The era boundary is 2003 (the death-certificate revision), NOT the ICD-9/
#' ICD-10 boundary at 1999. `age_years` is single completed years, so it is not
#' directly comparable to the pre-binned `ager27` recode consumed by
#' [convert_ager27()] / [categorize_age_5()]; to bin it into 5-year groups use,
#' e.g., `pmin(floor(age_years / 5) * 5, 85)`.
#'
#' @param df an MCOD data frame for a single data year, with the raw `age` column
#' @param year data year; if `NULL`, extracted from the data frame
#'
#' @return `df` with an added numeric `age_years` column
#' @importFrom dplyr case_when between
#' @export
#' @examples
#' df <- data.frame(year = 2019, age = c(1037, 2006, 1999, 9999))
#' remap_age(df)$age_years          # 37 (years), 0 (months), NA, NA
remap_age <- function(df, year = NULL) {
    if (is.null(year)) {
        year <- .extract_year(df)
    }
    if (is.null(df[["age"]])) {
        stop("remap_age() needs the raw detail-age column `age`.", call. = FALSE)
    }
    if (length(year) != 1L || is.na(year)) {
        stop("remap_age(): could not determine a single, non-missing data year.",
             call. = FALSE)
    }

    ## Coerce so a character/factor `age` compares numerically, not
    ## lexicographically.
    age_raw <- suppressWarnings(as.numeric(as.character(df[["age"]])))

    if (year >= 1979 && year <= 2002) {
        df$age_years <- .remap_age_pre2003(age_raw)
    } else if (year >= 2003) {
        df$age_years <- .remap_age_2003plus(age_raw)
    } else {
        stop(sprintf(
            paste0("remap_age(): cannot map age for year %s (expected a 4-digit ",
                   "MCOD data year >= 1979)."), year), call. = FALSE)
    }

    df
}

## 1979-2002 detail age (3-digit): units 0/1 = years (literal); 2-6 = sub-year
## (months/weeks/days/hours/minutes) -> 0; 999 = not stated -> NA.
.remap_age_pre2003 <- function(age_col) {
    dplyr::case_when(
        age_col == 999 ~ NA_real_,
        age_col < 200 ~ age_col,
        dplyr::between(age_col, 200, 699) ~ 0
    )
}

## 2003+ detail age (4-digit): unit 1 = years (code - 1000); 2/4/5/6 = sub-year
## -> 0; 1999 (years, number not stated) and 9999 (not stated) -> NA.
.remap_age_2003plus <- function(age_col) {
    dplyr::case_when(
        age_col == 9999 ~ NA_real_,
        age_col == 1999 ~ NA_real_,
        dplyr::between(age_col, 1000, 1998) ~ age_col - 1000,
        dplyr::between(age_col, 2000, 6999) ~ 0
    )
}
