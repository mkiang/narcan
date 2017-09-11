#' Download 1990s Population Counts
#'
#' Download US Census Bureau annual population estimates for the 1990s for
#' each age group and sex. Note that each population estimate file is
#' a little different and thus must be munged before being combined
#' into the total pop_est dataframe.
#'
#' @param filter_race Subset to white, nhw, black, and total (default: TRUE)
#'
#' @return Dataframe with population counts by age and sex
#' @source https://www.census.gov/programs-surveys/popest.html
#' @importFrom readr read_fwf fwf_positions
#' @importFrom dplyr mutate select filter
#' @importFrom tidyr gather
.download_1990s_pop_data <- function(filter_race = TRUE) {
    ## Files can be found at the `base_url` defined below.
    ##
    ## Documentation is here: paste0('https://www2.census.gov/programs-surveys',
    ##                               '/popest/technical-documentation/',
    ##                               'file-layouts/1980-1990/',
    ##                               'nat-detail-layout.txt')
    ##
    ## File comes in `rqi`, `cqi`, and `pqi` suffixes:
    ##  - rmp - resident population
    ##  - cmp - civilian population
    ##  - pmp - resident + armed forces
    ##
    ## We will use the rmp files.

    ## Set up URLS / filenames
    base_url  <- paste0('https://www2.census.gov/programs-surveys/popest/',
                        'datasets/1990-2000/national/asrh/')
    txt_files <- sprintf('e%s%srmp.txt', 90:99, 90:99)

    ## Define columns
    c_defs <- fwf_positions(start = c(1, 3, 5,  9, 12, seq(13, 213, 10)),
                            end   = c(2, 4, 8, 11, 12, seq(22, 222, 10)),
                            col_names = c("series", "month", "year",
                                          "age_years", "delete", "total",
                                          "total_male", "total_female",
                                          "white_male", "white_female",
                                          "black_male", "black_female",
                                          "aia_male", "aia_female",
                                          "api_male", "api_female",
                                          "hisp_male", "hisp_female",
                                          "nhw_male", "nhw_female",
                                          "nhb_male", "nhb_female",
                                          "nhaia_male", "nhaia_female",
                                          "nhapi_male", "nhapi_female"))

    ## Results holder
    holder <- NULL

    ## Loop through every 1990-1999 files
    for (f in txt_files) {
        # print(f)
        ## Define file location and url
        file_url <- sprintf('%s%s', base_url, f)

        ## Read
        temp_df <- read_fwf(file_url, col_positions = c_defs)

        ## Remove series column, filter rows
        temp_df <-  temp_df %>%
            select(-series, -delete) %>%
            filter(month == 7, age_years != 999) %>%
            select(-month)

        ## Reshape females
        female_df <- temp_df %>%
            select(year, age_years, contains("_female")) %>%
            gather(race, pop, total_female:nhapi_female) %>%
            mutate(sex = "female",
                   race = gsub(race, pattern = "_female", replacement = ""))

        ## Reshape males
        male_df <- temp_df %>%
            select(year, age_years, contains("_male")) %>%
            gather(race, pop, total_male:nhapi_male) %>%
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
        holder <- rbind(holder, total_df, male_df, female_df,
                        nhw_both_df, black_both_df, white_both_df)
    }

    ## Subset out black, nonhispanic white, and total
    if (filter_race) {
        holder <- filter(holder, race %in%
                             c("total", "black", "nhw", "white"))
    }

    return(holder)
}
