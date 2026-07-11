# Calculate age-specific rates and variance

Given a bare (unquoted) column of counts and population, will return the
rate in 100,000 as well as the variance (using Poisson approximation).

## Usage

``` r
calc_asrate_var(df, new_name, death_col, pop_col = pop)
```

## Arguments

- df:

  processed MCOD dataframe

- new_name:

  bare prefix of the new column names (e.g., opioid)

- death_col:

  column of counts for numerator of rate

- pop_col:

  column of population for denominator of rate

## Value

dataframe with two new columns

## Examples

``` r
df <- data.frame(deaths = c(10, 20), pop = c(1e5, 2e5))
calc_asrate_var(df, opioid, deaths)
#>   deaths   pop opioid_rate opioid_var
#> 1     10 1e+05          10         10
#> 2     20 2e+05          10          5
```
