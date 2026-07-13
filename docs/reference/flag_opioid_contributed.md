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

new dataframe with an \`opioid_contributed\` column (\`NA\` for
ICD-9-era data; see the note above)

## Details

For ICD-9-era data (pre-1999) this flag is undefined: narcan's ICD-9
opioid-death rule fires on any opioid code in any field, so an opioid
recorded only in a contributory cause already makes the death an opioid
death – there is no "opioid contributed but not the underlying opioid
death" subset to flag. On ICD-9 input the function therefore warns and
returns \`NA\` rather than a misleading 0/1. (For ICD-10 the
underlying-cause and contributory sets are disjoint, so the flag is well
defined.)

## Examples

``` r
df <- data.frame(year = 2019, ucod = "I250", f_records_all = "T401")
flag_opioid_contributed(df, year = 2019)
#>   year ucod f_records_all opioid_contributed
#> 1 2019 I250          T401                  1
```
