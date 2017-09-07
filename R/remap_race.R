#' Remaps the race column to a single standard across 1979-2015
#'
#' The race column in MCOD data underwent several changes from 1979-2015.
#' This function standardizes the race column and can (should) be used with
#' categorize_race() to result in a single set of consist race codes across
#' all files.
#'
#' @param icd_df an MCOD dataframe
#' @param year year of file, if NULL will try to extract year automatically
#'
#' @return dataframe
#' @importFrom dplyr case_when
#' @export
remap_race <- function(icd_df, year = NULL) {
    ## Extract year
    if (is.null(year)) {
        year <- .extract_year(icd_df)
    }

    ## Run appropriate function depending on year
    if (year >= 1979 & year <= 1988) {
        icd_df$race <- .remap_race_1979_1988(icd_df$race)
    } else if (year >= 1989 & year <= 1991) {
        icd_df$race <- .remap_race_1989_1991(icd_df$race)
    } else if (year >= 1992 & year <= 2015) {
        icd_df$race <- .remap_race_1992_2015(icd_df$race)
    } else {
        break
    }

    return(icd_df)
}

.remap_race_1979_1988 <- function(race_col) {
    new_col <- case_when(
        race_col == 0 ~ 99,
        race_col == 1 ~ 1,
        race_col == 2 ~ 2,
        race_col == 3 ~ 3,
        race_col == 4 ~ 4,
        race_col == 5 ~ 5,
        race_col == 6 ~ 6,
        race_col == 7 ~ 99,
        race_col == 8 ~ 7
    )
    return(new_col)
}

.remap_race_1989_1991 <- function(race_col) {
    new_col <- case_when(
        race_col == 1 ~ 1,
        race_col == 2 ~ 2,
        race_col == 3 ~ 3,
        race_col == 4 ~ 4,
        race_col == 5 ~ 5,
        race_col == 6 ~ 6,
        race_col == 7 ~ 7,
        race_col == 8 ~ 99,
        race_col == 9 ~ 99
    )
    return(new_col)
}

.remap_race_1992_2015 <- function(race_col) {
    new_col <- case_when(
        race_col == 1 ~ 1,
        race_col == 2 ~ 2,
        race_col == 3 ~ 3,
        race_col == 4 ~ 4,
        race_col == 5 ~ 5,
        race_col == 6 ~ 6,
        race_col == 7 ~ 7,
        race_col == 18 ~ 99,
        race_col == 28 ~ 99,
        race_col == 38 ~ 99,
        race_col == 48 ~ 99,
        race_col == 58 ~ 99,
        race_col == 68 ~ 99,
        race_col == 78 ~ 99
    )
    return(new_col)
}
