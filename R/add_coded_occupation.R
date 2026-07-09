#' Add harmonized coded occupation and industry columns
#'
#' Coded occupation and industry appear in the MCOD files under two different,
#' **non-comparable** coding schemes at different byte positions and column names.
#' This helper hides those details: given an imported MCOD data frame and its data
#' year, it appends standardized columns (`occ_coded`, `ind_coded`, their recodes,
#' the scheme, and an availability flag) so downstream code does not need to know
#' which era or tier the data came from.
#'
#' @details
#' Availability matrix (coded occupation/industry):
#' \tabular{lll}{
#'   \strong{Years} \tab \strong{Scheme} \tab \strong{Notes} \cr
#'   1985-1999 \tab `3digit_census` \tab 1980-Census basis 1985-1992, 1990-Census
#'     1993-1999; source columns `occup` (@88-90) and `industry` (@85-87);
#'     state-dependent coverage \cr
#'   2000-2019 \tab (none) \tab coded occupation/industry not collected \cr
#'   2020+ \tab `4digit_niosh` \tab NCHS+NIOSH 4-digit codes; source columns
#'     `occupation`/`occupationr` (@806-811) and `industry`/`industryr` (@812-817)
#' }
#' The 3-digit (1985-1999) and 4-digit (2020+) codes are **not comparable** -- do
#' not chain a series across the gap. Tier difference: the 4-digit codes reach the
#' \strong{public} file in data year 2020 but the \strong{restricted} file only in
#' 2021, so `occ_coded` is all-`NA` for restricted 2020 (use the public file for
#' 2020 occupation); from 2021 the public and restricted codes are identical.
#'
#' @param df a data frame imported via [import_mcod_fwf()] (or
#'   `.import_restricted_data()`)
#' @param year the data year of `df` (integer)
#'
#' @return `df` with added columns: `occ_scheme` (character, the coding scheme or
#'   `NA`), `occ_coded`, `ind_coded`, `occ_recode`, `ind_recode`, and
#'   `occ_available` (logical; `TRUE` when the scheme applies and `occ_coded` has
#'   any non-missing value)
#' @export
#'
#' @examples
#' \dontrun{
#' df <- import_mcod_fwf("mort2023us.dat", 2023, tier = "public")
#' df <- add_coded_occupation(df, 2023)
#' table(df$occ_scheme)          # "4digit_niosh"
#' }
add_coded_occupation <- function(df, year) {
    col <- function(nm) if (!is.null(df[[nm]])) df[[nm]] else NA

    scheme <- if (year >= 1985 && year <= 1999) {
        "3digit_census"
    } else if (year >= 2020) {
        "4digit_niosh"
    } else {
        NA_character_
    }

    if (identical(scheme, "3digit_census")) {
        occ <- col("occup")
        ind <- col("industry")
        occ_r <- NA
        ind_r <- NA
    } else if (identical(scheme, "4digit_niosh")) {
        occ <- col("occupation")
        ind <- col("industry")
        occ_r <- col("occupationr")
        ind_r <- col("industryr")
    } else {
        occ <- NA
        ind <- NA
        occ_r <- NA
        ind_r <- NA
    }

    df$occ_scheme <- scheme
    df$occ_coded <- occ
    df$ind_coded <- ind
    df$occ_recode <- occ_r
    df$ind_recode <- ind_r
    df$occ_available <- !is.na(scheme) && any(!is.na(occ))
    df
}
