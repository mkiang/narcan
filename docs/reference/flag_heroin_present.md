# Creates a new column called heroin_present if opioid death involved heroin

Heroin deaths were recorded in both ICD-9 and ICD-10 years. This creates
a new column to flag when that death involved heroin and was an opioid
death as defined by flag_opioid_death().

## Usage

``` r
flag_heroin_present(processed_df, year = NULL, keep_cols = FALSE)
```

## Arguments

- processed_df:

  MCOD dataframe already processed

- year:

  if NULL, will attempt to detect

- keep_cols:

  keep intermediate columns

## Value

a new dataframe with a binary heroin_present column

## Examples

``` r
df <- data.frame(year = 2019, ucod = "X42", f_records_all = "T401 T400")
flag_heroin_present(df, year = 2019)
#>   year ucod f_records_all heroin_present
#> 1 2019  X42     T401 T400              1
```
