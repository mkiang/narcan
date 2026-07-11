# Rename nature of injury columns for consistency

Some of the NBER ICD-9 MCOD files use rniflag\_ as a column name while
others use rnifla\_. This function makes the names consistent (to
rnifla\_).

## Usage

``` r
rename_ni_flag(icd9_df)
```

## Arguments

- icd9_df:

  an ICD-9 dataframe

## Value

dataframe

## Examples

``` r
df <- data.frame(rniflag_1 = c(0, 1), record_1 = c("E850", "9650"))
rename_ni_flag(df)
#>   rnifla_1 record_1
#> 1        0     E850
#> 2        1     9650
```
