# Creates a column called \`other_synth_present\`

Note that ICD9 years did not include an other synthetic opioid code. We
code it as 0 by default, but can be coded however specified in
missing_val parameter. This function flags all opioid deaths that
involved other synthetic opioid.

## Usage

``` r
flag_other_synth_present(
  processed_df,
  year = NULL,
  missing_val = 0,
  opioid_deaths_only = TRUE
)
```

## Arguments

- processed_df:

  MCOD dataframe already processed

- year:

  if NULL, will attempt to detect

- missing_val:

  value to indicate missing (i.e., code did not exist)

- opioid_deaths_only:

  if \`TRUE\` (default) the flag fires only on opioid deaths
  (\`opioid_death == 1\`); if \`FALSE\`, it fires wherever the code
  appears (including contributory-only records) and the caller is
  expected to \`filter(opioid_death == 1)\` themselves.

## Value

a new dataframe with 1 additional column

## Examples

``` r
df <- data.frame(year = 2019, ucod = "X42", f_records_all = "T404")
df |>
    flag_opioid_deaths(year = 2019) |>
    flag_other_synth_present(year = 2019)
#>   year ucod f_records_all opioid_death other_synth_present
#> 1 2019  X42          T404            1                   1
```
