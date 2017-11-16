## Saves a simple dataframe of Appalachian counties. Work comes from:
## https://github.com/davemistich/election-appalachia/issues/1
appalachia_fips <- readr::read_csv(paste0("./inst/extdata/",
                                          "appal-counties-geoid.csv")) %>%
    rename(st_abbrev = state_abb,
           state = state_full,
           county_name = state_county,
           fipschar = geoid) %>%
    ungroup()

devtools::use_data(appalachia_fips, overwrite = TRUE)

