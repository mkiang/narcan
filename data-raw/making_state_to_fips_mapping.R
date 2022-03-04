## Saves a simple dataframe of state/territory name, abbrevaition, fips
st_fips_map <- readr::read_csv("./inst/extdata/state_to_fips.csv") %>%
    ungroup()

usethis::use_data(st_fips_map, overwrite = TRUE)

