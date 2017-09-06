#' Download 1979 Population Counts
#'
#' Download US Census Bureau annual population estimates for 1979 for
#' each age group and sex. Note that each population estimate file is
#' a little different and thus must be munged before being combined
#' into the total pop_est dataframe.
#'
#' @return Dataframe with population counts by age and sex
#' @source https://www.census.gov/programs-surveys/popest.html
#' @importFrom readr read_csv
#' @importFrom dplyr mutate select ends_with contains
#' @importFrom tidyr gather

.download_1979_pop_data <- function() {
    ## Downloads 1979 data. "Documentation" can be found here:
    ##  paste0("https://www2.census.gov/programs-surveys/popest/",
    ##         "tables/1900-1980/national/asrh/pe-11-1979.pdf")
    file_url <- paste0('https://www2.census.gov/programs-surveys/popest/',
                       'tables/1900-1980/national/asrh/pe-11-1979.csv')

    ## First few lines are notes. Last few are footnotes.
    temp_df <- read_csv(file_url,
                        skip = 8, n_max = 86,
                        col_names = c("age_years",
                                      "total_both", "total_male",
                                      "total_female",
                                      "white_both", "white_male",
                                      "white_female",
                                      "black_both", "black_male",
                                      "black_female",
                                      "other_both", "other_male",
                                      "other_female"))

    ## Fix age
    temp_df <- temp_df %>%
        mutate(age_years = 0:85,
               year = 1979)

    ## Both sexes
    both_sex <- temp_df %>%
        select(age_years, year, ends_with("_both")) %>%
        gather(race, pop, total_both:other_both) %>%
        mutate(race = gsub(race, pattern = "_both", replacement = ""),
               sex = "both")

    ## Females
    females <- temp_df %>%
        select(age_years, year, ends_with("_female")) %>%
        gather(race, pop, total_female:other_female) %>%
        mutate(race = gsub(race, pattern = "_female", replacement = ""),
               sex = "female")

    ## Males
    males <- temp_df %>%
        select(age_years, year, ends_with("_male")) %>%
        gather(race, pop, total_male:other_male) %>%
        mutate(race = gsub(race, pattern = "_male", replacement = ""),
               sex = "male")

    ## Combined
    holder <- rbind(both_sex, females, males)

    return(holder)
}
