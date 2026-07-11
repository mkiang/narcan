# Converts the age27 variable in MCOD data to 5-year age groups

Converts the age27 variable in MCOD data to 5-year age groups

## Usage

``` r
convert_ager27(icd_df, remove_age27 = TRUE)
```

## Arguments

- icd_df:

  an MCOD dataframe with age27 as a column

- remove_age27:

  once a new column is created, remove the old age27

## Value

dataframe

## Examples

``` r
df <- data.frame(ager27 = c(1, 10, 23, 27))
convert_ager27(df)
#>   age
#> 1   0
#> 2  20
#> 3  85
#> 4  NA
```
