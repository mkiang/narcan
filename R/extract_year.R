#' Helper function that extracts year from a dataframe and raises error
#' if more than one.
#'
#' MCOD files name the year column `year` from data year 1996 onward but
#' `datayear` for 1979-1995. This checks `year` first, then falls back to
#' `datayear`, and errors if neither column is present.
#'
#' The 1979-1995 files store `datayear` as a two-digit value (e.g. 85 for 1985).
#' A two-digit value is normalized to its four-digit year (+1900), since every
#' two-digit `datayear` is a 19xx year. Without this, downstream year dispatch
#' (`.dispatch_era()`, `remap_race()`, `categorize_hspanicr()`) sees a value like
#' 85 that matches no coding era and either errors or silently mislabels.
#'
#' @param df dataframe to extract year from
#'
#' @return year as integer (four-digit)
#' @keywords internal
.extract_year <- function(df) {
    if (!is.null(df$year)) {
        year <- unique(df$year)
    } else if (!is.null(df$datayear)) {
        year <- unique(df$datayear)
    } else {
        stop("No `year` or `datayear` column found.")
    }

    if (length(year) > 1) {
        stop("Too many years.")
    }

    ## Coerce to numeric so a character/factor datayear (e.g. "85" read from a
    ## CSV) compares numerically, not lexicographically, then normalize a
    ## two-digit datayear (79-95) to its four-digit year.
    year <- suppressWarnings(as.numeric(as.character(year)))
    if (!is.na(year) && year < 100) {
        year <- year + 1900
    }

    return(year)
}

#' Best-effort year detection that never errors (unlike .extract_year)
#'
#' Returns the explicit `year` if given, else the first value of a `year` or
#' `datayear` column if present, else NULL. Used by the ICD-9 guards so a
#' year-less data frame preserves current behavior rather than erroring.
#'
#' @param df dataframe
#' @param year explicit year (or NULL to detect)
#' @return a single year, or NULL if undeterminable
#' @keywords internal
.detect_year_safe <- function(df, year = NULL) {
    if (!is.null(year)) {
        return(year)
    }
    if (!is.null(df$year)) {
        return(unique(df$year)[1])
    }
    if (!is.null(df$datayear)) {
        return(unique(df$datayear)[1])
    }
    NULL
}

#' Warn that an ICD-10-only flag was handed pre-1999 (ICD-9) data
#'
#' Emits a single warning when `year` is determinable and < 1999, so ICD-9 years
#' do not silently return all zeros. Does nothing when `year` is NULL/NA. ICD-9
#' cause detection is not implemented (a future work item).
#'
#' @param year a single year (or NULL)
#' @param fn name of the calling function (for the message)
#' @return invisibly NULL
#' @keywords internal
.warn_icd9_only <- function(year, fn) {
    if (!is.null(year) && !is.na(year) && year < 1999) {
        warning(sprintf(
            paste0("%s() supports only ICD-10 (year >= 1999). Pre-1999 (ICD-9) ",
                   "data returns all zeros; ICD-9 suicide coding is not yet ",
                   "implemented."),
            fn
        ), call. = FALSE)
    }
    invisible(NULL)
}

#' Is this an ICD-9 data year? (US MCOD coded causes in ICD-9 for 1979-1998)
#'
#' Central definition of the ICD-9 era boundary shared by the flag_* family
#' and unite_records() so the magic numbers live in one place.
#'
#' @param year a single year
#' @return logical
#' @keywords internal
.is_icd9 <- function(year) {
    year >= 1979 & year <= 1998
}

#' Is this an ICD-10 data year? (US MCOD adopted ICD-10 from 1999)
#'
#' @param year a single year
#' @return logical
#' @keywords internal
.is_icd10 <- function(year) {
    year >= 1999
}

#' Dispatch the ICD coding era for a data year
#'
#' Single source of truth for era selection across the flag_* family and
#' unite_records(). Returns "icd9" (1979-1998) or "icd10" (>= 1999) and errors
#' on a 2-digit `datayear` (e.g. 93) or any 4-digit year before 1979, so an
#' out-of-range year can never silently fall through into the wrong branch.
#'
#' @param year a single 4-digit data year
#' @return "icd9" or "icd10"
#' @keywords internal
.dispatch_era <- function(year) {
    ## Coerce so a character/factor year compares numerically -- a lexicographic
    ## comparison would misroute a value like "85" into the ICD-10 branch.
    year <- suppressWarnings(as.numeric(as.character(year)))
    if (length(year) != 1L || is.na(year)) {
        stop("`year` must be a single, non-missing value.", call. = FALSE)
    }
    if (.is_icd9(year)) {
        return("icd9")
    }
    if (.is_icd10(year)) {
        return("icd10")
    }
    stop(sprintf(
        paste0("Cannot determine an ICD coding era for year %s: expected a ",
               "4-digit year in 1979-1998 (ICD-9) or >= 1999 (ICD-10). ",
               "Two-digit `datayear` values (e.g. 93) are unsupported -- pass ",
               "an explicit 4-digit `year`."),
        year), call. = FALSE)
}
