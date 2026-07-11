# Converts the age27 variable in MCOD data to under-1, 1-4, then 5-year groups

Converts the age27 variable in MCOD data to under-1, 1-4, then 5-year
groups

## Usage

``` r
convert_ager27u1(icd_df, remove_age27 = TRUE)
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
df <- data.frame(ager27 = c(1, 3, 10, 27))
convert_ager27u1(df)
#>   age
#> 1   0
#> 2   1
#> 3  20
#> 4  NA
```
