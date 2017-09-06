#' Download 1980s Population Counts
#'
#' Download US Census Bureau annual population estimates for the 1980s for
#' each age group and sex. Note that each population estimate file is
#' a little different and thus must be munged before being combined
#' into the total pop_est dataframe.
#'
#' @return Dataframe with population counts by age and sex
#' @source https://www.census.gov/programs-surveys/popest.html
#' @importFrom readr read_fwf fwf_positions
#' @importFrom dplyr mutate select
#' @importFrom tidyr gather
.download_1980s_pop_data <- function(raw_folder = "./raw_data",
                                    filter_race = TRUE) {
    ## Files can be found at the `base_url` defined below.
    ##
    ## Documentation is here: paste0('https://www2.census.gov/programs-surveys',
    ##                               '/popest/technical-documentation/',
    ##                               'file-layouts/1980-1990/',
    ##                               'nat-detail-layout.txt')
    ##  NOTE: The documentation is wrong and specifies in the incorrect
    ##          column width. In addition, the lasta line of every file
    ##          has a strange encoding and throws an error. Therefore,
    ##          I count the number of line breaks and then subtract one to get
    ##          the n_max argument. Each file is relatively small so this
    ##          is fine, but if we run into very large files, I'll need to
    ##          think of a better method.
    ##
    ## File comes in `rqi`, `cqi`, and `pqi` suffixes:
    ##  - rqi - resident population
    ##  - cqi - civilian population
    ##  - pqi - resident + armed forces
    ##
    ## We will use the RQI files.

    ## Set up URLS / filenames
    base_url  <- paste0('https://www2.census.gov/programs-surveys/popest',
                        '/datasets/1980-1990/national/asrh/')
    zip_files <- paste0('e', 80:89, 81:90, 'rqi.zip')

    ## Make directory
    mkdir_p(raw_folder)

    ## Define columns
    c_defs <- fwf_positions(start = c(1, 3, 5, 7, 10, seq(21, 211, 10)),
                            end   = c(2, 4, 6, 9, 20, seq(30, 220, 10)),
                            col_names = c("series", "month", "year",
                                          "age_years", "total",
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

    ## Loop through every 1980-1989 file
    holder <- NULL
    for (f in zip_files) {
        # print(f)
        ## Define file location and url
        file_url <- sprintf('%s%s', base_url, f)
        dest_loc <- sprintf('%s/%s', raw_folder, f)

        ## Download and unzip
        download.file(file_url, dest_loc)
        unzip(dest_loc, exdir = raw_folder)

        ## Define number of rows
        n_rows <- sum(count.fields(sprintf("%s/%s.TXT", raw_folder,
                                           substr(toupper(f), 1, nchar(f) - 4)),
                                   sep = "\n")) - 1

        ## Read
        temp_df <- read_fwf(sprintf("%s/%s.TXT", raw_folder,
                                    substr(toupper(f), 1, nchar(f) - 4)),
                            col_positions = c_defs,
                            n_max = n_rows)

        ## Remove series column, filter rows
        temp_df <- temp_df %>%
            select(-series) %>%
            filter(month == 7, age_years != 999) %>%
            mutate(year = as.integer(paste0("19", year))) %>%
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

        ## Clean up
        file.remove(dest_loc)
        file.remove(sprintf("%s/%s.TXT", raw_folder,
                            substr(toupper(f), 1, nchar(f) - 4)))

    }

    ## Subset out black, nonhispanic white, and total
    if (filter_race) {
        holder <- filter(holder, race %in%
                             c("total", "black", "nhw", "white"))
    }

    return(holder)
}
