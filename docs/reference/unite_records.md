# Unite the 20 record columns from MCOD dataframe into a single column

This function collapses the 20 contributory cause columns into a single
column for easier regex'ing. ICD-9 dataframes will also get appropriate
prefixes before collapsing.

## Usage

``` r
unite_records(icd_df, year = NULL)
```

## Arguments

- icd_df:

  an ICD dataframe

- year:

  the year of this dataframe – if NULL, will attempt to detect

## Value

dataframe

## Examples

``` r
df <- data.frame(
    year = 2019,
    record_1 = c("X42", "I250"),
    record_2 = c("T401", "")
)
unite_records(df, year = 2019)
#>   year f_records_all
#> 1 2019      X42 T401
#> 2 2019          I250
```
