# Download 2000s Population Counts

Download US Census Bureau annual population estimates for the 2000s for
each age group and sex. Note that each population estimate file is a
little different and thus must be munged before being combined into the
total pop_est dataframe.

## Usage

``` r
.download_2000s_pop_data(filter_race = TRUE)
```

## Source

https://www.census.gov/programs-surveys/popest.html

## Arguments

- filter_race:

  Subset to white, nhw, black, and total (default: TRUE)

## Value

Dataframe with population counts by age and sex
