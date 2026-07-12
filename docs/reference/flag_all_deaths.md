# Run the canonical MCOD flagging pipeline

Convenience wrapper that runs the standard raw-MCOD-to-flags chain in
one call: unite the record columns, then flag drug deaths, opioid
deaths, opioid types, and overdose intent. It is purely additive – each
step is the existing exported function, run in the canonical order with
the data year resolved once.

## Usage

``` r
flag_all_deaths(
  df,
  year = NULL,
  clean_icd9 = FALSE,
  types = TRUE,
  intent = TRUE,
  opioid_deaths_only = TRUE
)
```

## Arguments

- df:

  an MCOD data frame (a single data year)

- year:

  data year; if \`NULL\`, extracted from \`df\`

- clean_icd9:

  if \`TRUE\`, also run \[clean_icd9_data()\] on ICD-9-era data
  (1979-1998) before uniting records. Usually unnecessary:
  \[unite_records()\] auto-cleans raw ICD-9 data, and
  \[clean_icd9_data()\] is idempotent (a no-op on already-clean data).
  It never runs on ICD-10 data regardless of this flag. Default
  \`FALSE\`.

- types:

  if \`TRUE\` (default), also run \[flag_opioid_types()\]

- intent:

  if \`TRUE\` (default), also run \[flag_od_intent()\]

- opioid_deaths_only:

  forwarded to \[flag_opioid_types()\] (see its help)

## Value

the input data frame with the flag columns added

## Examples

``` r
df <- data.frame(year = 2019, ucod = "X42", f_records_all = "T401 T404")
flag_all_deaths(df, year = 2019)
#>   year ucod f_records_all drug_death opioid_death opium_present heroin_present
#> 1 2019  X42     T401 T404          1            1             0              1
#>   other_natural_present methadone_present other_synth_present other_op_present
#> 1                     0                 0                   1                0
#>   unspecified_op_present num_opioids multi_opioids unintended_intent
#> 1                      0           2             1                 1
#>   suicide_intent homicide_intent undetermined_intent
#> 1              0               0                   0
```
