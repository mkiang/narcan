# Flag non-opioid deaths that involved opioids

Given an MCOD dataframe, will search through contributory causes for
opioid related codes, but will only flag rows for which the underlying
cause is \*\*NOT\*\* an opioid-related death.

## Usage

``` r
flag_opioid_contributed(processed_df, year = NULL)
```

## Arguments

- processed_df:

  processed dataframe

- year:

  if NULL, will attempt to detect

## Value

new dataframe with an opioid_contributed column

## Details

NOTE: This function really doesn't make sense for ICD-9 years. Use with
caution.

## Examples

``` r
df <- data.frame(year = 2019, ucod = "I250", f_records_all = "T401")
flag_opioid_contributed(df, year = 2019)
#>   year ucod f_records_all opioid_contributed
#> 1 2019 I250          T401                  1
```
