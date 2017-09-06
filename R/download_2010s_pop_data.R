#' Download 2010s Population Counts
#'
#' Download US Census Bureau annual population estimates for the 2010s for
#' each age group and sex. Note that each population estimate file is
#' a little different and thus must be munged before being combined
#' into the total pop_est dataframe.
#'
#' @return Dataframe with population counts by age and sex
#' @source https://www.census.gov/programs-surveys/popest.html
#' @importFrom readr read_csv
#' @import dplyr
#' @importFrom stats setNames
#' @importFrom tidyr gather

.download_2010s_pop_data <- function(filter_race = TRUE) {
    ## Source: paste0("https://www2.census.gov/programs-surveys/",
    ##                "popest/datasets/2010-2015/state/asrh/")
    ##
    ## Documentation: paste0("https://www2.census.gov/programs-surveys",
    ##                       "/popest/datasets/2010-2015/state/asrh/",
    ##                       "sc-est2015-alldata6.pdf")
    file_url <- paste0("https://www2.census.gov/programs-surveys/",
                       "popest/datasets/2010-2015/state/asrh/",
                       "sc-est2015-alldata6.csv")

    ## Download and make column names lowercase
    pop_raw <- read_csv(file_url) %>%
        setNames(tolower(names(.)))

    ## Remove columns we don't need. 2010 estimates will come
    ## from download_2000s_pop_data()
    temp_df <- pop_raw %>%
        select(-census2010pop, -popestimate2010, -estimatesbase2010) %>%
        rename(age_years = age) %>%
        select(-sumlev, -region, -division, -state, -name)

    ## Create race codes consistent with previous years
    temp_df <- temp_df %>%
        rename(race_original = race) %>%
        mutate(race = case_when(
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
    total_pop <- temp_df %>%
        filter(origin == 0) %>%
        select(-race, -race_original) %>%
        group_by(sex, age_years, origin) %>%
        summarize_all(sum) %>%
        mutate(race = "total",
               race_original = NA) %>%
        ungroup()

    ## Collapse down populations (over state)
    temp_df <- temp_df %>%
        group_by(sex, origin, race_original, race, age_years) %>%
        summarize_all(sum) %>%
        ungroup()

    ## Combine
    temp_df <- rbind(temp_df, total_pop)

    ## Reshape
    temp_df <- temp_df %>%
        gather(year, value = pop,
               popestimate2011:popestimate2015)

    ## Fix year and sex columns
    temp_df <- temp_df %>%
        mutate(year = as.integer(substr(year, 12, 15)),
               sex = case_when(
                   sex == 0 ~ "both",
                   sex == 1 ~ "male",
                   sex == 2 ~ "female",
                   TRUE ~ NA_character_)) %>%
        select(year, age_years, pop, sex, race)

    ## Filter race
    if (filter_race) {
        temp_df <- filter(temp_df, race %in%
                              c("total", "nhw", "black", "white"))
    }

    return(temp_df)
}
