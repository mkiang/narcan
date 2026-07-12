# Creates a new column called heroin_present if opioid death involved heroin

Heroin deaths were recorded in both ICD-9 and ICD-10 years. This creates
a new column to flag when that death involved heroin and was an opioid
death as defined by flag_opioid_death().

## Usage

``` r
flag_heroin_present(
  processed_df,
  year = NULL,
  keep_cols = FALSE,
  opioid_deaths_only = TRUE
)
```

## Arguments

- processed_df:

  MCOD dataframe already processed

- year:

  if NULL, will attempt to detect

- keep_cols:

  keep intermediate columns

- opioid_deaths_only:

  if \`TRUE\` (default) the flag fires only on opioid deaths
  (\`opioid_death == 1\`); if \`FALSE\`, it fires wherever the heroin
  code appears (including contributory-only records) and the caller is
  expected to \`filter(opioid_death == 1)\` themselves.

## Value

a new dataframe with a binary heroin_present column

## Examples

``` r
df <- data.frame(year = 2019, ucod = "X42", f_records_all = "T401 T400")
flag_heroin_present(df, year = 2019)
#>   year ucod f_records_all heroin_present
#> 1 2019  X42     T401 T400              1
```
