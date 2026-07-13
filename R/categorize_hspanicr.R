#' Create a categorical Hispanic origin/race column from the hspanicr column
#'
#' The hspanicr (Hispanic Origin/Race Recode) column was not recorded before
#' 1989 and its coding changed across data years: a 9-category scheme through
#' 2020, reserved/not populated in 2021, and an expanded 14-category (single-race,
#' 1997 OMB) scheme from 2022. This labels each value using the scheme that
#' applies to its data year, so functions like tidyr::complete() will expand rows
#' that have no observations.
#'
#' The pre-2022 and 2022+ schemes are not comparable -- the old "Central or South
#' American" splits into Dominican, Central American, and South American, and
#' non-Hispanics gain single-race detail -- so a factor spanning the 2021
#' boundary must not be treated as a single ordered scale.
#'
#' @param hspanicr_column hspanicr column from an MCOD dataframe
#' @param year data year(s); a single value or a vector aligned to
#'   \code{hspanicr_column}. If \code{NULL}, the pre-2022 9-category scheme is
#'   assumed (with a warning) for backward compatibility.
#'
#' @return an ordered factor
#' @seealso \code{\link{categorize_hispanic_origin}} for the binary
#'   \code{hispanic}/\code{non_hispanic} origin axis used for population joins
#'   (this function returns the full 9/14-category ethnicity recode, for
#'   descriptive counts, which has no matching denominator).
#' @export
#'
#' @examples
#' categorize_hspanicr(c(1:5, NA, 9, 8, 4), year = 2019)
#' categorize_hspanicr(c(1, 4, 10, 13, 14), year = 2023)
categorize_hspanicr <- function(hspanicr_column, year = NULL) {
    labels_9 <- c("mexican", "puerto_rican", "cuban", "central_south_america",
                  "other_hispanic", "nonhispanic_white", "nonhispanic_black",
                  "nonhispanic_other", "hispanic_unknown")
    labels_14 <- c("mexican", "puerto_rican", "cuban", "dominican",
                   "central_american", "south_american", "other_hispanic",
                   "nonhispanic_white", "nonhispanic_black", "nonhispanic_aian",
                   "nonhispanic_asian", "nonhispanic_nhopi", "nonhispanic_multi",
                   "hispanic_unknown")
    union_levels <- c("mexican", "puerto_rican", "cuban",
                      "central_south_america", "dominican", "central_american",
                      "south_american", "other_hispanic", "nonhispanic_white",
                      "nonhispanic_black", "nonhispanic_other",
                      "nonhispanic_aian", "nonhispanic_asian",
                      "nonhispanic_nhopi", "nonhispanic_multi",
                      "hispanic_unknown")

    ## Coerce by VALUE, not factor position: as.integer(factor("9")) returns the
    ## level's ordinal position, not 9, so a factor-valued hspanicr would silently
    ## mis-recode (alphabetical level order diverges from numeric for codes 10-14).
    ## as.character() first -- the idiom this file already uses for `year` below.
    code <- as.integer(as.character(hspanicr_column))
    n <- length(code)

    if (is.null(year)) {
        warning("`year` not supplied to categorize_hspanicr(); assuming the ",
                "pre-2022 9-category scheme. Pass `year` to label 2022+ data ",
                "correctly.")
        yr <- rep(2000L, n)
    } else {
        ## Coerce by VALUE, not factor position -- same idiom as `hspanicr_column`
        ## above and as categorize_hispanic_origin(): a factor-valued `year` would
        ## otherwise map to its level index, silently mis-selecting the era.
        yr <- suppressWarnings(as.integer(as.numeric(as.character(year))))
        if (length(yr) == 1L) {
            yr <- rep(yr, n)
        } else if (length(yr) != n) {
            stop("`year` must be length 1 or the same length as ",
                 "`hspanicr_column`.")
        }
    }

    ## map a contiguous 1..length(labels) code vector to labels, NA otherwise
    lab <- function(cd, labels) {
        ok <- !is.na(cd) & cd >= 1L & cd <= length(labels)
        res <- rep(NA_character_, length(cd))
        res[ok] <- labels[cd[ok]]
        res
    }

    legacy <- !is.na(yr) & yr >= 1989 & yr <= 2020
    new14 <- !is.na(yr) & yr >= 2022

    out <- rep(NA_character_, n)
    out[legacy] <- lab(code[legacy], labels_9)
    out[new14] <- lab(code[new14], labels_14)

    ## Warn on codes outside the valid range for their era (mirrors
    ## categorize_hispanic_origin()): an out-of-range or era-mismatched code
    ## (e.g. a 14-category code paired with a pre-2022 year) is otherwise silently
    ## NA'd by lab() -- the strata-corrupting failure mode the recodes guard
    ## against elsewhere.
    bad <- !is.na(code) & (legacy | new14) & is.na(out)
    if (any(bad)) {
        warning(sprintf(paste0(
            "categorize_hspanicr(): %d hspanicr value(s) are outside the valid ",
            "code range for their data year and were set to NA."), sum(bad)),
            call. = FALSE)
    }

    if (any(!is.na(yr) & yr == 2021)) {
        warning("hspanicr is reserved/not populated for 2021; ",
                "returning NA for those rows.")
    }

    lvls <- if (any(new14) && any(legacy)) {
        union_levels
    } else if (any(new14)) {
        labels_14
    } else {
        labels_9
    }

    return(factor(out, levels = lvls, ordered = TRUE))
}
