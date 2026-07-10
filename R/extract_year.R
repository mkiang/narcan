#' Helper function that extracts year from a dataframe and raises error
#' if more than one.
#'
#' MCOD files name the year column `year` from data year 1996 onward but
#' `datayear` for 1979-1995. This checks `year` first, then falls back to
#' `datayear`, and errors if neither column is present.
#'
#' @param df dataframe to extract year from
#'
#' @return year as integer
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
