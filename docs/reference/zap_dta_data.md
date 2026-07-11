# Clear Stata metadata from MCOD dta files

The NBER MCOD dta files come with a variety of metadata not necessary
for use in R. This function clears all metadata as well as replacing NAN
and blanks ("") with NA.

## Usage

``` r
zap_dta_data(dta_df)
```

## Arguments

- dta_df:

  dataframe from imported dta (e.g., from haven::read_dta())

## Value

dataframe

## Examples

``` r
df <- data.frame(x = c(1, NaN, 3), y = c("a", "", "c"))
zap_dta_data(df)
#>    x    y
#> 1  1    a
#> 2 NA <NA>
#> 3  3    c
```
