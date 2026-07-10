#' Create a categorical race column from a standardized race column
#'
#' Labels the standardized race codes produced by remap_race(). The bridged-race
#' scheme (2020 and earlier) uses codes 0-7 and 99; the single-race scheme (2022+)
#' uses the non-colliding codes 101-106. The factor levels adapt to whichever
#' scheme(s) are present, so pre-2021 data is labeled exactly as before.
#'
#' The single-race categories are labeled with an `_only` suffix (matching the
#' NCHS "(only)" wording) and are NOT comparable to the bridged categories -- do
#' not combine the two schemes into a single trend.
#'
#' @param race_column race column created from remap_race()
#'
#' @return an ordered factor
#' @export
#'
#' @examples
#' categorize_race(c(0, 1, 1, 1, 0:7, 99))
#' categorize_race(c(101, 102, 104, 106))
categorize_race <- function(race_column) {
    bridged_levels <- c(0:7, 99)
    bridged_labels <- c("total", "white", "black", "american_indian",
                        "chinese", "japanese", "hawaiian", "filipino", "other")
    single_levels <- 101:106
    single_labels <- c("white_only", "black_only", "american_indian_only",
                       "asian_only", "nhopi_only", "multiracial")

    has_single <- any(race_column %in% single_levels, na.rm = TRUE)
    has_bridged <- any(race_column %in% bridged_levels, na.rm = TRUE)

    if (has_single) {
        warning("single-race codes (101-106) are not comparable to the bridged ",
                "race scheme (2020 and earlier); do not combine the two into a ",
                "single trend.")
    }

    if (has_single && !has_bridged) {
        lvls <- single_levels
        labs <- single_labels
    } else if (has_single && has_bridged) {
        lvls <- c(bridged_levels, single_levels)
        labs <- c(bridged_labels, single_labels)
    } else {
        lvls <- bridged_levels
        labs <- bridged_labels
    }

    x <- factor(race_column, levels = lvls, labels = labs, ordered = TRUE)
    return(x)
}
