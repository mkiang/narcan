## This file creates a dataset that contains counts of live births between
## 2003 and 2016 by race/ethnicity using the CDC NCHS Natality Data.
##
## Step 1 downloads all the data. They are approximately 200 MB each.
## Step 2 will then unzip each file (one by one). Unzipped, the files are
##      about 5 GB. It will then import only the columns we want, collapse
##      the data, and save just the aggregated data.
## Step 3 will then combine all aggregated datasets, import, and then delete
##      the source files and downloaded zip files.

## Imports
library(tidyverse)
library(narcan)

## Helpers
## R can't unzip files that result in something larger than 4GB so we use
## the `system2` command to invoke the local unzip utility.
decompress_file <- function(directory, file, .file_cache = FALSE) {
    ## From: https://stackoverflow.com/questions/42740206/

    if (.file_cache == TRUE) {
        print("decompression skipped")
    } else {

        # Set working directory for decompression
        # simplifies unzip directory location behavior
        wd <- getwd()
        setwd(directory)

        # Run decompression
        decompression <-
            system2("unzip",
                    args = c("-o", # include override flag
                             file),
                    stdout = TRUE)

        # Reset working directory
        setwd(wd); rm(wd)

        # Test for success criteria
        # change the search depending on
        # your implementation
        if (grepl("Warning message", tail(decompression, 1))) {
            print(decompression)
        }
    }
}

## First, download all the zips
years <- 2003:2016

for (year in years) {
    if (length(list.files("./raw_data", pattern = as.character(year)) > 0)) {
        next
    }
    current_file <- narcan:::download_natality_ascii(year, return_path = TRUE)
    print(current_file)
    Sys.sleep(runif(1, 0, 30))
}

## Unzip them
for (year in years) {
    ## Find the current file in the raw folder
    current_file <- list.files("./raw_data", as.character(year),
                               full.names = FALSE)

    decompress_file("./raw_data", current_file)

    print(current_file)
}

## Now for each, read in the data, aggregate by race/ethnicity,
## save the aggregated data.
decompressed_files <- list.files("./raw_data", "dat|txt", full.names = TRUE)

for (year in years) {
    ## Find the current file in the raw folder
    current_file <- decompressed_files[grep(paste0("Nat", year),
                                            decompressed_files)]

    print(current_file)

    ## Get the widths and columns
    nber_dict <- narcan:::.dct_to_fwf_df(year, natality = TRUE) %>%
        filter(start > lag(end),
               name %in% c("mager9", "restatus",
                           "mbrace", "mracerec",
                           "mhisp_r", "umhisp"))

    ## Import the data
    temp_df <-
        readr::read_fwf(current_file,
                        col_positions = fwf_positions(start = nber_dict$start,
                                                      end = nber_dict$end,
                                                      col_names = nber_dict$name),
                        col_types = paste(nber_dict$type, collapse = ""))

    ## Deal with variable name changes
    if (tibble::has_name(temp_df, "umhisp")) {
        temp_df <- temp_df %>%
            rename(mhisp_r = umhisp)
    }

    if (tibble::has_name(temp_df, "mracerec")) {
        temp_df <- temp_df %>%
            mutate(mbrace = mracerec) %>%
            select(-mracerec)
    }

    ## Fix some of the columns
    temp_df <- temp_df %>%
        narcan::subset_residents(.) %>%
        mutate(mother_age = 10 + (mager9 - 1)*5,
               bridge_race =
                   case_when(mbrace == 1 ~ "white",
                             mbrace == 2 ~ "black",
                             mbrace == 3 ~ "aia",
                             mbrace == 4 ~ "api",
                             TRUE ~ "unknown"),
               hispanic =
                   case_when(mhisp_r == 0 ~ "non_hisp",
                             mhisp_r == 9 ~ "unknown",
                             TRUE ~ "hisp")) %>%
        select(bridge_race, hispanic, mother_age)

    ## Aggregate through different combinations:
        ##  Total
        ##  Non-Hispanic white
        ##  Non-Hispanic black
        ##  Non-Hispanic other
        ##  All white
        ##  All black
        ##  All other
        ##  All hispanic
        ##  All non-hispanic

    agg_df <- bind_rows(
        temp_df %>%
            group_by(mother_age) %>%
            summarize(births = n()) %>%
            mutate(m_race_eth = "total"),
        temp_df %>%
            filter(hispanic == "non_hisp",
                   bridge_race == "white") %>%
            group_by(mother_age) %>%
            summarize(births = n()) %>%
            mutate(m_race_eth = "non_hisp_white"),
        temp_df %>%
            filter(hispanic == "non_hisp",
                   bridge_race == "black") %>%
            group_by(mother_age) %>%
            summarize(births = n()) %>%
            mutate(m_race_eth = "non_hisp_black"),
        temp_df %>%
            filter(hispanic == "non_hisp",
                   bridge_race %in% c("aia", "api")) %>%
            group_by(mother_age) %>%
            summarize(births = n()) %>%
            mutate(m_race_eth = "non_hisp_other"),
        temp_df %>%
            filter(bridge_race %in% c("white")) %>%
            group_by(mother_age) %>%
            summarize(births = n()) %>%
            mutate(m_race_eth = "all_hisp_white"),
        temp_df %>%
            filter(bridge_race %in% c("black")) %>%
            group_by(mother_age) %>%
            summarize(births = n()) %>%
            mutate(m_race_eth = "all_hisp_black"),
        temp_df %>%
            filter(bridge_race %in% c("aia", "api")) %>%
            group_by(mother_age) %>%
            summarize(births = n()) %>%
            mutate(m_race_eth = "all_hisp_other"),
        temp_df %>%
            filter(hispanic == "non_hisp") %>%
            group_by(mother_age) %>%
            summarize(births = n()) %>%
            mutate(m_race_eth = "non_hisp_total"),
        temp_df %>%
            filter(hispanic == "hisp") %>%
            group_by(mother_age) %>%
            summarize(births = n()) %>%
            mutate(m_race_eth = "hisp_total")
    ) %>% mutate(year = year)

    saveRDS(agg_df, sprintf("./raw_data/agg_df_%s.RDS", year))
}

live_births <- list.files("./raw_data", "\\.RDS", full.names = TRUE) %>%
    map(readRDS) %>%
    reduce(rbind)

devtools::use_data(live_births, overwrite = TRUE)
