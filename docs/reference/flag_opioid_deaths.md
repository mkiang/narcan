# Flag opioid deaths according to ISW7 rules

Given an MCOD dataframe, will apply ISW7 rules to flag opioid deaths for
both ICD9 and ICD10 codes. Expects you to run unite_records() first. If
you don't, it will do so, but will remove that columns by default.
Change keep_cols = TRUE to keep it.

## Usage

``` r
flag_opioid_deaths(processed_df, year = NULL, keep_cols = FALSE)
```

## Arguments

- processed_df:

  processed dataframe

- year:

  if NULL, will attempt to detect

- keep_cols:

  keep intermediate columns

## Value

new dataframe with a binary opioid_death column

## Note

"Any opioid" includes T40.6 ("other and unspecified narcotics"),
following ISW7 and NCHS. Per the ISW7 (2012) Appendix B1 footnote, T40.6
can capture non-opioids (e.g., cocaine) in some jurisdictions.

## Examples

``` r
df <- data.frame(year = 2019, ucod = "X42", f_records_all = "T401")
flag_opioid_deaths(df, year = 2019)
#>   year ucod f_records_all opioid_death
#> 1 2019  X42          T401            1
```
