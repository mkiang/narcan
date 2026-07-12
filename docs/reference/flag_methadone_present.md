# Creates a column \`methadone_present\` if opioid death involved methadone

This function flags all opioid deaths that involved methadone.

## Usage

``` r
flag_methadone_present(
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
  (\`opioid_death == 1\`); if \`FALSE\`, it fires wherever the methadone
  code appears (including contributory-only records) and the caller is
  expected to \`filter(opioid_death == 1)\` themselves.

## Value

a new dataframe with 1 additional column

## Examples

``` r
df <- data.frame(year = 2019, ucod = "X42", f_records_all = "T403")
df |>
    flag_opioid_deaths(year = 2019) |>
    flag_methadone_present(year = 2019)
#>   year ucod f_records_all opioid_death methadone_present
#> 1 2019  X42          T403            1                 1
```
