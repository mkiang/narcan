# Summarizes all flagged (e.g., 0/1) MCOD columns

To use this, you must remove all non-grouping, non-binary variables.

## Usage

``` r
summarize_binary_columns(df, ...)
```

## Arguments

- df:

  a dataframe with binary flag columns to indicate type of death

- ...:

  grouping variables (in addition to year and age)

## Value

dataframe

## Examples

``` r
df <- data.frame(
    year = c(2019, 2019),
    age = c(25, 25),
    age_cat = c("20-24", "20-24"),
    opioid_death = c(1, 0),
    drug_death = c(1, 1)
)
summarize_binary_columns(df)
#> # A tibble: 1 × 6
#> # Groups:   year, age [1]
#>    year   age age_cat deaths opioid_death drug_death
#>   <dbl> <dbl> <chr>    <int>        <dbl>      <dbl>
#> 1  2019    25 20-24        2            1          2
```
