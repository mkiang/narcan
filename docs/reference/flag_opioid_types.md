# Take a processed MCOD dataframe and create indicators for opioid types

Creates 9 indicators for all opioid deaths. 7 for type of opioid (opium,
heroin, natural, methadone, synthetic, other, unknown), 1 column for the
number of opioids, and 1 column to indicate presence of more than one
opioid.

## Usage

``` r
flag_opioid_types(processed_df, year = NULL, opioid_deaths_only = TRUE)
```

## Arguments

- processed_df:

  MCOD dataframe already processed

- year:

  if NULL, will attempt to detect

- opioid_deaths_only:

  if \`TRUE\` (default), types are flagged only for opioid deaths
  (\`opioid_death == 1\`) – the historical behavior. If \`FALSE\`, an
  opioid \*type\* is flagged wherever its code appears in the
  contributory causes, even when the death is not an opioid death under
  the ISW7 combined rule; the presence of an opioid in contributory
  causes does NOT mean the death was an opioid death, so the caller is
  expected to \`filter(opioid_death == 1)\` themselves. See issue \#2.

## Value

a new dataframe with 9 additional columns

## Examples

``` r
df <- data.frame(year = 2019, ucod = "X42", f_records_all = "T401 T404")
df |>
    flag_opioid_deaths(year = 2019) |>
    flag_opioid_types(year = 2019)
#>   year ucod f_records_all opioid_death opium_present heroin_present
#> 1 2019  X42     T401 T404            1             0              1
#>   other_natural_present methadone_present other_synth_present other_op_present
#> 1                     0                 0                   1                0
#>   unspecified_op_present num_opioids multi_opioids
#> 1                      0           2             1
```
