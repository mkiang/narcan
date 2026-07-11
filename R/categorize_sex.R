#' Categorize the NCHS sex field across coding eras
#'
#' NCHS changed the sex coding at data year 2003: 1979-2002 use a numeric code
#' (`1` = male, `2` = female); 2003 onward use a character code (`"M"`, `"F"`).
#' This maps either scheme to the strings `"male"` / `"female"` (and `NA` for
#' anything else), matching the `sex` labels used by [pop_est] so downstream
#' population joins need no relabeling.
#'
#' The era is taken from `year` when supplied (authoritative). When `year` is
#' `NULL`, the era is inferred from the column's type -- a numeric column is the
#' pre-2003 scheme, a character column the 2003+ scheme -- with a warning; pass
#' `year` to be explicit (a character `"1"`/`"2"` re-read from a CSV would
#' otherwise be treated as the modern scheme and map to `NA`).
#'
#' @param sex_column a vector of raw NCHS sex codes
#' @param year data year: a scalar, a vector aligned to `sex_column`, or `NULL`
#'   to infer the era from the column type
#'
#' @return a character vector of `"male"` / `"female"` / `NA`
#' @export
#' @examples
#' categorize_sex(c(1, 2, 9), year = 2000)      # "male" "female" NA
#' categorize_sex(c("M", "F", "U"), year = 2019) # "male" "female" NA
categorize_sex <- function(sex_column, year = NULL) {
    n <- length(sex_column)

    if (is.null(year)) {
        modern <- rep(!is.numeric(sex_column), n)
        warning("categorize_sex(): `year` not supplied; inferring the coding ",
                "era from the column type (",
                if (modern[1]) "2003+ 'M'/'F'" else "pre-2003 1/2",
                "). Pass `year` to be explicit.", call. = FALSE)
    } else {
        if (length(year) == 1L) {
            year <- rep(year, n)
        }
        modern <- year >= 2003
    }

    x <- as.character(sex_column)
    out <- rep(NA_character_, n)

    legacy <- !modern & !is.na(modern)
    out[legacy & x == "1"] <- "male"
    out[legacy & x == "2"] <- "female"

    recent <- modern & !is.na(modern)
    out[recent & toupper(x) == "M"] <- "male"
    out[recent & toupper(x) == "F"] <- "female"

    if (n > 0L && all(is.na(out))) {
        warning("categorize_sex(): every value mapped to NA -- this usually ",
                "means the `year`/era does not match the column's coding ",
                "(numeric 1/2 vs character M/F).", call. = FALSE)
    }

    out
}

#' Flag female deaths across coding eras
#'
#' A thin wrapper on [categorize_sex()] returning `1` for female, `0` for male,
#' and `NA` for an unmapped/missing code.
#'
#' @param sex_column a vector of raw NCHS sex codes
#' @param year data year: a scalar, a vector aligned to `sex_column`, or `NULL`
#'   to infer the era from the column type
#'
#' @return an integer vector of `1` (female) / `0` (male) / `NA`
#' @export
#' @examples
#' categorize_female(c(1, 2), year = 2000)      # 0 1
#' categorize_female(c("M", "F"), year = 2019)  # 0 1
categorize_female <- function(sex_column, year = NULL) {
    labels <- categorize_sex(sex_column, year = year)
    out <- rep(NA_integer_, length(labels))
    out[labels == "female"] <- 1L
    out[labels == "male"] <- 0L
    out
}
