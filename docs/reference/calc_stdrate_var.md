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

  grouping variables. These are \*\*not\*\* added automatically: pass
  every dimension you want preserved in the output (e.g. \`year\`,
  \`race\`), or pre-group \`df\`. Age bins are collapsed into the
  standardized rate.

- weight_col:

  column of (unit) weights

## Value

dataframe with two new columns

## Examples

``` r
df <- data.frame(
    year = c(2015, 2015),
    race = c("white", "white"),
    opioid_rate = c(5, 7),
    opioid_var = c(0.1, 0.2),
    unit_w = c(0.5, 0.5)
)
calc_stdrate_var(df, opioid_rate, opioid_var, year, race)
#> # A tibble: 1 × 4
#> # Groups:   year [1]
#>    year race  opioid_rate opioid_var
#>   <dbl> <chr>       <dbl>      <dbl>
#> 1  2015 white           6      0.075
```
