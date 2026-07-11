# Calculate age-standardized rates and variance

Given a bare (unquoted) column of age-specific rates, variance, and
weights, will return the age-standardized rate and variance.

## Usage

``` r
calc_stdrate_var(df, asrate_col, asvar_col, ..., weight_col = unit_w)
```

## Arguments

- df:

  processed MCOD dataframe

- asrate_col:

  age-specific rate column

- asvar_col:

  variance of the age-specific rate

- ...:

  grouping variables (in addition to year and race)

- weight_col:

  column of (unit) weights

## Value

dataframe with two new columns

## Examples

``` r
df <- data.frame(
    race = c("white", "white"),
    opioid_rate = c(5, 7),
    opioid_var = c(0.1, 0.2),
    unit_w = c(0.5, 0.5)
)
calc_stdrate_var(df, opioid_rate, opioid_var, race)
#> # A tibble: 1 × 3
#>   race  opioid_rate opioid_var
#>   <chr>       <dbl>      <dbl>
#> 1 white           6      0.075
```
