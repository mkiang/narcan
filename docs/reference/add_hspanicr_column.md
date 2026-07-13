# Add an NA hspanicr column if one doesn't exist

Hispanic origin was not recorded until 1989. In order to keep all
dataframes conformable, add an NA column named hspanicr if one does not
exist.

## Usage

``` r
add_hspanicr_column(icd_df)
```

## Arguments

- icd_df:

  an MCOD dataframe)

## Value

dataframe

## See also

[`add_hispanic_origin`](https://mkiang.github.io/narcan/reference/add_hispanic_origin.md),
which adds the binary `hispanic_origin` column (for population joins)
derived from `hspanicr`; this function only backfills the raw `hspanicr`
field.

## Examples

``` r
df <- data.frame(year = 2019, ucod = "X42")
add_hspanicr_column(df)
#>   year ucod hspanicr
#> 1 2019  X42       NA
```
