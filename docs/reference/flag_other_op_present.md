# Creates a column \`other_op_present\` for deaths with other unspecified opioid

This function flags all opioid deaths that involved other unspecified
opioid

## Usage

``` r
flag_other_op_present(processed_df, year = NULL, opioid_deaths_only = TRUE)
```

## Arguments

- processed_df:

  MCOD dataframe already processed

- year:

  if NULL, will attempt to detect

- opioid_deaths_only:

  if \`TRUE\` (default) the flag fires only on opioid deaths
  (\`opioid_death == 1\`); if \`FALSE\`, it fires wherever the code
  appears (including contributory-only records) and the caller is
  expected to \`filter(opioid_death == 1)\` themselves.

## Value

a new dataframe with 1 additional column

## Examples

``` r
df <- data.frame(year = 2019, ucod = "X42", f_records_all = "T406")
df |>
    flag_opioid_deaths(year = 2019) |>
    flag_other_op_present(year = 2019)
#>   year ucod f_records_all opioid_death other_op_present
#> 1 2019  X42          T406            1                1
```
