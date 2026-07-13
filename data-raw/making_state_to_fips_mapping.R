## Saves a simple dataframe of state name, abbreviation, FIPS, and NCHS code.
## narcan is US-only (50 states + DC); territories/associated states (FIPS >= 60)
## are dropped. Their NCHS state codes in the source are unreliable -- American
## Samoa and the Northern Mariana Islands both carry 62, and Micronesia/Marshall
## Islands/Palau/Minor Outlying Islands have no NCHS code -- and the public and
## restricted "us" MCOD files narcan processes never carry them. The raw CSV
## keeps all rows; the shipped dataset is filtered to states + DC.
st_fips_map <- readr::read_csv("./inst/extdata/state_to_fips.csv") %>%
    dplyr::ungroup() %>%
    dplyr::filter(fips <= 56)

usethis::use_data(st_fips_map, overwrite = TRUE)

