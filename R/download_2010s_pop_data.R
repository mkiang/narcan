#' Download 2010s Population Counts
#'
#' Download US Census Bureau annual population estimates for the 2010s for
#' each age group and sex. Note that each population estimate file is
#' a little different and thus must be munged before being combined
#' into the total pop_est dataframe.
#'
#' @param filter_race Subset to white, nhw, black, and total (default: TRUE)
#'
#' @return Dataframe with population counts by age and sex
#' @source https://www.census.gov/programs-surveys/popest.html
#' @importFrom readr read_csv
#' @importFrom dplyr select rename mutate case_when filter group_by ungroup summarize_all starts_with
#' @importFrom tidyr pivot_longer
#' @keywords internal

.download_2010s_pop_data <- function(filter_race = TRUE) {
    ## Source: paste0("https://www2.census.gov/programs-surveys/",
    ##                "popest/datasets/2010-2017/state/asrh/")
    ##
    ## Documentation: paste0("https://www2.census.gov/programs-surveys",
    ##                       "/popest/datasets/2010-2015/state/asrh/",
    ##                       "sc-est2015-alldata6.pdf")
    file_url <- paste0("https://www2.census.gov/programs-surveys/",
                       "popest/datasets/2010-2020/state/asrh/",
                       "SC-EST2020-ALLDATA6.csv")

    ## Download and make column names lowercase
    pop_raw <- readr::read_csv(file_url)
    names(pop_raw) <- tolower(names(pop_raw))

    ## Remove columns we don't need. 2010 estimates will come
    ## from download_2000s_pop_data()
    temp_df <- pop_raw |>
        dplyr::select(-census2010pop, -popestimate2010, -estimatesbase2010) |>
        dplyr::rename(age_years = age) |>
        dplyr::select(-sumlev, -region, -division, -state, -name)

    ## Create race codes consistent with previous years
    temp_df <- temp_df |>
        dplyr::rename(race_original = race) |>
        dplyr::mutate(race = dplyr::case_when(
            ## Total origin for each race
            origin == 0 & race_original == 1 ~ "white",
            origin == 0 & race_original == 2 ~ "black",
            origin == 0 & race_original == 3 ~ "aia",
            origin == 0 & race_original == 4 ~ "azn",
            origin == 0 & race_original == 5 ~ "pi",
            origin == 0 & race_original == 6 ~ "tom",
            ## NonHispanic origin of each race
            origin == 1 & race_original == 1 ~ "nhw",
            origin == 1 & race_original == 2 ~ "nhb",
            origin == 1 & race_original == 3 ~ "nhaia",
            origin == 1 & race_original == 4 ~ "nhazn",
            origin == 1 & race_original == 5 ~ "nhpi",
            origin == 1 & race_original == 6 ~ "nhtom",
            ## Hispanic origin for each race
            origin == 2 & race_original == 1 ~ "hwa",
            origin == 2 & race_original == 2 ~ "hba",
            origin == 2 & race_original == 3 ~ "haia",
            origin == 2 & race_original == 4 ~ "hazn",
            origin == 2 & race_original == 5 ~ "hpi",
            origin == 2 & race_original == 6 ~ "htom"))

    ## Create a total population count
    total_pop <- temp_df |>
        dplyr::filter(origin == 0) |>
        dplyr::select(-race, -race_original) |>
        dplyr::group_by(sex, age_years, origin) |>
        dplyr::summarize_all(sum) |>
        dplyr::mutate(race = "total",
               race_original = NA) |>
        dplyr::ungroup()

    ## Collapse down populations (over state)
    temp_df <- temp_df |>
        dplyr::group_by(sex, origin, race_original, race, age_years) |>
        dplyr::summarize_all(sum) |>
        dplyr::ungroup()

    ## Combine
    temp_df <- rbind(temp_df, total_pop)

    ## Reshape
    temp_df <- temp_df |>
        tidyr::pivot_longer(dplyr::starts_with("popestimate"),
                     names_to = "year", values_to = "pop")

    ## Fix year and sex columns
    temp_df <- temp_df |>
        dplyr::mutate(year = as.integer(substr(year, 12, 15)),
               sex = dplyr::case_when(
                   sex == 0 ~ "both",
                   sex == 1 ~ "male",
                   sex == 2 ~ "female",
                   TRUE ~ NA_character_)) |>
        dplyr::select(year, age_years, pop, sex, race)

    ## Filter race
    if (filter_race) {
        temp_df <- dplyr::filter(temp_df, race %in%
                              c("total", "nhw", "black", "white"))
    }

    return(temp_df)
}
