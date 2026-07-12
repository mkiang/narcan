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
#'   1982-1999 \tab `3digit_census` \tab 1980-Census basis 1982-1992, 1990-Census
#'     1993-1999; source columns `occup` (@88-90) and `industry` (@85-87);
#'     state-dependent coverage \cr
#'   2000-2019 \tab (none) \tab coded occupation/industry not collected \cr
#'   2020+ \tab `4digit_niosh` \tab NCHS+NIOSH 4-digit codes; source columns
#'     `occupation`/`occupationr` (@806-811) and `industry`/`industryr` (@812-817)
#' }
#' The 3-digit (1982-1999) and 4-digit (2020+) codes are **not comparable** -- do
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
    if (length(year) != 1L || is.na(year)) {
        stop("add_coded_occupation(): `year` must be a single non-NA value.",
             call. = FALSE)
    }

    if (nrow(df) == 0L) {
        df$occ_scheme <- character(0)
        df$occ_coded <- character(0)
        df$ind_coded <- character(0)
        df$occ_recode <- character(0)
        df$ind_recode <- character(0)
        df$occ_available <- logical(0)
        return(df)
    }

    col <- function(nm) if (!is.null(df[[nm]])) df[[nm]] else NA

    scheme <- if (year >= 1982 && year <= 1999) {
        "3digit_census"
    } else if (year >= 2020) {
        "4digit_niosh"
    } else {
        NA_character_
    }

    ## Zero-pad to a fixed-width CHARACTER code so the harmonized columns are
    ## type-stable across eras (numeric 7 and character "0110" cannot bind_rows())
    ## and leading zeros survive both the 3-digit Census and 4-digit NIOSH codes.
    ## as.character() first so a factor input yields its LABEL not its level code
    ## (the project's as.integer(as.character(.)) idiom).
    pad_code <- function(x, width) {
        if (is.null(x)) return(NA_character_)
        xi <- suppressWarnings(as.integer(as.character(x)))
        out <- ifelse(is.na(xi), NA_character_,
                      formatC(xi, width = width, flag = "0"))
        out
    }

    if (identical(scheme, "3digit_census")) {
        occ <- pad_code(col("occup"), 3L)
        ind <- pad_code(col("industry"), 3L)
        occ_r <- NA_character_
        ind_r <- NA_character_
    } else if (identical(scheme, "4digit_niosh")) {
        occ <- pad_code(col("occupation"), 4L)
        ind <- pad_code(col("industry"), 4L)
        ## the recodes are 2-char NCHS/NIOSH codes (@810-811, @816-817), a
        ## different width from the 4-digit coded columns; pad to width 2 (not
        ## 4) so leading zeros survive numeric input too.
        occ_r <- pad_code(col("occupationr"), 2L)
        ind_r <- pad_code(col("industryr"), 2L)
    } else {
        occ <- NA_character_
        ind <- NA_character_
        occ_r <- NA_character_
        ind_r <- NA_character_
    }

    df$occ_scheme <- scheme
    df$occ_coded <- occ
    df$ind_coded <- ind
    df$occ_recode <- occ_r
    df$ind_recode <- ind_r
    df$occ_available <- !is.na(scheme) && any(!is.na(occ))
    df
}
