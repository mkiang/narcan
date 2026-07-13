# Flag overdose deaths by their UCOD intent code

Flag overdose deaths by their UCOD intent code

## Usage

``` r
flag_od_intent(processed_df, year = NULL)
```

## Arguments

- processed_df:

  MCOD dataframe already processed

- year:

  if NULL, will attempt to extract

## Value

dataframe

## Details

Intent is read from the underlying-cause code. For ICD-9-era data this
interacts with narcan's ICD-9 "any-mention" drug-death rule: a death can
be a drug death because a drug/opioid code appears in a contributory
field while its underlying cause is a determinate NON-drug mechanism
(e.g. E955 firearm suicide with an opiate elsewhere on the record). Such
a death matches none of the four drug-poisoning intent sub-ranges and is
labeled \`undetermined_intent\`. This is deliberate – narcan derives
overdose intent only from a drug-poisoning underlying cause and will not
import a non-drug manner of death into the drug-intent columns (which
would pull, say, firearm suicides into the suicide-overdose count). The
\*manner\* of these deaths is known; what is undetermined is the intent
of the drug involvement.

## Examples

``` r
df <- data.frame(
    year = 2019,
    ucod = c("X42", "X62"),
    f_records_all = c("T400", "T400")
)
df |>
    flag_drug_deaths(year = 2019) |>
    flag_od_intent(year = 2019)
#>   year ucod f_records_all drug_death unintended_intent suicide_intent
#> 1 2019  X42          T400          1                 1              0
#> 2 2019  X62          T400          1                 0              1
#>   homicide_intent undetermined_intent
#> 1               0                   0
#> 2               0                   0
```
