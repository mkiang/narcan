#' Remaps the race column to a standardized code across data years
#'
#' The race coding in MCOD data changed repeatedly. Through 2020 the bridged-race
#' detailed `race` column is standardized to a common set (white, black, American
#' Indian, and the Asian/Pacific Islander subgroups, with the remainder collapsed
#' to 99). From 2022 the bridged race column is gone; this reads the single-race
#' Race Recode 6 (`racer5`) instead and maps it to a non-colliding code space
#' (101-106) so bridged and single-race values can share one column without being
#' confused. Data year 2021 is a transition gap -- the bridged race fields are
#' dropped and the single-race recodes are not yet populated -- so `race` is set
#' to NA.
#'
#' Bridged (2020 and earlier) and single-race (2022+) codes are NOT comparable
#' and must not be chained into a single trend. Use with categorize_race().
#'
#' @param icd_df an MCOD dataframe (a single data year)
#' @param year year of file; if NULL will try to extract year automatically
#'
#' @return dataframe with a standardized `race` column
#' @importFrom dplyr case_when
#' @export
#' @examples
#' df <- data.frame(year = 2019, race = c(1, 2, 3, 18))
#' remap_race(df, year = 2019)
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
    } else if (year >= 1992 & year <= 2020) {
        icd_df$race <- .remap_race_1992_2020(icd_df$race)
    } else if (year == 2021) {
        warning("race is retired in 2021 (bridged race dropped; single-race ",
                "recodes not populated until 2022); setting race to NA.")
        icd_df$race <- NA_real_
    } else if (year >= 2022) {
        if (is.null(icd_df$racer5)) {
            stop("remap_race() needs the single-race `racer5` (Race Recode 6) ",
                 "column for 2022+ data.")
        }
        warning("2022+ race uses the single-race Race Recode 6 mapped to codes ",
                "101-106; these are NOT comparable to the bridged race scheme ",
                "(2020 and earlier).")
        icd_df$race <- .remap_race_2022plus(icd_df$racer5)
    } else {
        stop(sprintf(
            paste0("remap_race(): cannot map race for year %s. Expected a ",
                   "4-digit MCOD data year >= 1979. (A 2-digit datayear is ",
                   "normalized by .extract_year(); pass a 4-digit `year` if you ",
                   "supplied it explicitly.)"),
            year), call. = FALSE)
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

.remap_race_1992_2020 <- function(race_col) {
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

.remap_race_2022plus <- function(racer5_col) {
    new_col <- case_when(
        racer5_col == 1 ~ 101,
        racer5_col == 2 ~ 102,
        racer5_col == 3 ~ 103,
        racer5_col == 4 ~ 104,
        racer5_col == 5 ~ 105,
        racer5_col == 6 ~ 106
    )
    return(new_col)
}
