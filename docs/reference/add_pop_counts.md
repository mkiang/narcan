# Given a dataframe with year, age, sex, and race, returns population estimate

Uses the internal narcan::pop_est dataset to return yearly population
estimates by age, sex, and race. See narcan::pop_est for columns and
possible values of each matching variable

## Usage

``` r
add_pop_counts(df, by_vars = c("year", "age", "sex", "race"))
```

## Arguments

- df:

  MCOD dataframe

- by_vars:

  variables to match on

## Value

dataframe

## Note

Denominators are bridged-race population estimates, which NCHS
discontinued after Vintage 2020. Rates for data year 2021 onward require
single-race population estimates (and the 2003 numeric-\>M/F \`sex\`
recode must be reconciled). Do not divide single-race death counts (see
remap_race() for 2022+) by these bridged-race denominators. Single-race
denominator support is a separate, future work item.

## Examples

``` r
df <- data.frame(year = 2019, age = 25, sex = "male", race = "white")
add_pop_counts(df)
#>   year age  sex  race     pop
#> 1 2019  25 male white 8739704
```
