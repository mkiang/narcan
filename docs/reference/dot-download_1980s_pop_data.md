# Download 1980s Population Counts

Download US Census Bureau annual population estimates for the 1980s for
each age group and sex. Note that each population estimate file is a
little different and thus must be munged before being combined into the
total pop_est dataframe.

## Usage

``` r
.download_1980s_pop_data(raw_folder = "./raw_data", filter_race = TRUE)
```

## Source

https://www.census.gov/programs-surveys/popest.html

## Arguments

- raw_folder:

  location to store downloaded files

- filter_race:

  Subset to white, nhw, black, and total (default: TRUE)

## Value

Dataframe with population counts by age and sex
