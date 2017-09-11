#' Download 2000s Population Counts
#'
#' Download US Census Bureau annual population estimates for the 2000s for
#' each age group and sex. Note that each population estimate file is
#' a little different and thus must be munged before being combined
#' into the total pop_est dataframe.
#'
#' @param filter_race Subset to white, nhw, black, and total (default: TRUE)
#'
#' @return Dataframe with population counts by age and sex
#' @source https://www.census.gov/programs-surveys/popest.html
#' @importFrom readr read_csv
#' @importFrom dplyr mutate select filter
#' @importFrom tidyr gather

.download_2000s_pop_data <- function(filter_race = TRUE) {
    ## Source: paste0("https://www2.census.gov/programs-surveys/popest/",
    ##                "datasets/2000-2010/intercensal/national/")
    ##
    ## Documentation: paste0("https://www2.census.gov/programs-surveys/",
    ##                       "popest/technical-documentation/file-layouts/",
    ##                       "2000-2010/intercensal/national/",
    ##                       "us-est00int-alldata.pdf)

    file_url <- paste0("https://www2.census.gov/programs-surveys/popest/",
                       "datasets/2000-2010/intercensal/national/",
                       "us-est00int-alldata.csv")
    temp_df <- read_csv(file_url)

    names(temp_df) <- c("month", "year",
                        "age_years", "total",
                        "total_male", "total_female",
                        "white_male", "white_female",
                        "black_male", "black_female",
                        "aia_male", "aia_female",
                        "azn_male", "azn_female",
                        "pi_male", "pi_female",
                        "tom_male", "tom_female",
                        "nonhisp_male", "nonhisp_female",
                        "nhw_male", "nhw_female",
                        "nhb_male", "nhb_female",
                        "nhaia_male", "nhaia_female",
                        "nhazn_male", "nhazn_female",
                        "nhpi_male", "nhpi_female",
                        "nhtom_male", "nhtom_female",
                        "h_male", "h_female",
                        "hwa_male", "hwa_female",
                        "hba_male", "hba_female",
                        "haia_male", "haia_female",
                        "hazn_male", "hazn_female",
                        "hpi_male", "hpi_female",
                        "htom_male", "htom_female")

    temp_df <-  temp_df %>%
        filter(month == 7, age_years != 999) %>%
        select(-month)

    ## Reshape females
    female_df <- temp_df %>%
        select(year, age_years, contains("_female")) %>%
        gather(race, pop, total_female:htom_female) %>%
        mutate(sex = "female",
               race = gsub(race, pattern = "_female", replacement = ""))

    ## Reshape males
    male_df <- temp_df %>%
        select(year, age_years, contains("_male")) %>%
        gather(race, pop, total_male:htom_male) %>%
        mutate(sex = "male",
               race = gsub(race, pattern = "_male", replacement = ""))

    ## Reshape total
    total_df <- temp_df %>%
        select(year, age_years, pop = total) %>%
        mutate(sex = "both",
               race = "total")

    ## Reshape nhw (both sexes)
    nhw_both_df <- temp_df %>%
        select(year, age_years, contains("nhw_")) %>%
        mutate(pop = nhw_male + nhw_female,
               sex = "both",
               race = "nhw") %>%
        select(-nhw_male, -nhw_female)

    ## Reshape white (both sexes)
    white_both_df <- temp_df %>%
        select(year, age_years, contains("white_")) %>%
        mutate(pop = white_male + white_female,
               sex = "both",
               race = "white") %>%
        select(-white_male, -white_female)

    ## Reshape black (both sexes)
    black_both_df <- temp_df %>%
        select(year, age_years, contains("black_")) %>%
        mutate(pop = black_male + black_female,
               sex = "both",
               race = "black") %>%
        select(-black_male, -black_female)

    ## Combine
    holder <- rbind(total_df, male_df, female_df,
                    nhw_both_df, black_both_df, white_both_df)

    ## Subset out black, nonhispanic white, and total
    if (filter_race) {
        holder <- filter(holder, race %in%
                             c("total", "black", "nhw", "white"))
    }

    ## Return
    return(holder)
}
