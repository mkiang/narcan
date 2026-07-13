# Classifying overdose deaths (ISW7)

narcan operationalizes the Injury Surveillance Workgroup (ISW7; Safe
States Alliance) case definitions for drug- and opioid-involved overdose
deaths, reading them straight off ICD-10 multiple-cause-of-death (MCOD)
records. A death is classified from two fields – the **underlying
cause** (`ucod`, e.g. `"X42"`) and the space-joined string of all
contributory **T-codes** (`f_records_all`, e.g. `"T404 T406"`). One
caveat matters for fentanyl. T40.4 (“synthetic opioids other than
methadone”) is the CDC-standard proxy for illicitly manufactured
fentanyl, which has dominated that code since roughly 2013 – but narcan
carries no fentanyl-*only* flag, because the ICD-10 code itself cannot
separate fentanyl from other synthetic opioids.

``` r

library(narcan)
```

## An illustrative record-level frame

The rows below are **synthetic and illustrative** – hand-written to span
the opioid subtypes, not real NCHS records. Each row carries only the
two fields the classifiers key on, plus `restatus` (residency status).
Six rows walk through the opioid subtypes, one is a non-opioid drug
death, two are non-drug deaths, and one is a non-resident
(`restatus = 4`).

``` r

deaths <- data.frame(
    ucod = c(
        "X42", "X42", "X44", "X42", "X42",
        "Y12", "X40", "I250", "C509", "X42"
    ),
    f_records_all = c(
        "T400", "T401 T404", "T402", "T403", "T404",
        "T406", "T436", "I250", "C509", "T404 T401"
    ),
    restatus = c(1L, 1L, 1L, 3L, 1L, 2L, 1L, 1L, 1L, 4L),
    stringsAsFactors = FALSE
)
deaths
#>    ucod f_records_all restatus
#> 1   X42          T400        1
#> 2   X42     T401 T404        1
#> 3   X44          T402        1
#> 4   X42          T403        3
#> 5   X42          T404        1
#> 6   Y12          T406        2
#> 7   X40          T436        1
#> 8  I250          I250        1
#> 9  C509          C509        1
#> 10  X42     T404 T401        4
```

## Keep US residents only

[`subset_residents()`](https://mkiang.github.io/narcan/reference/subset_residents.md)
keeps `restatus %in% 1:3` (US residents) and drops the `restatus` column
once it has filtered on it.

``` r

resident_deaths <- subset_residents(deaths)
nrow(deaths)            # 10 synthetic rows
#> [1] 10
nrow(resident_deaths)   # non-resident (restatus 4) dropped -> 9
#> [1] 9
```

## Run the flag pipeline, one step at a time

Three flaggers run in sequence. Each one adds columns and never drops a
row, so you can watch the classification build up step by step. Pass
`year` to select the coding era.

In real use, `f_records_all` is not hand-built – you read the raw
fixed-width MCOD file with
[`import_mcod_fwf()`](https://mkiang.github.io/narcan/reference/import_mcod_fwf.md)
and collapse its multiple-cause fields with
[`unite_records()`](https://mkiang.github.io/narcan/reference/unite_records.md).
See
[`vignette("getting-started")`](https://mkiang.github.io/narcan/articles/getting-started.md)
for that on-ramp, which is where a newcomer with real data should start.

**Step 1.**
[`flag_drug_deaths()`](https://mkiang.github.io/narcan/reference/flag_drug_deaths.md)
adds `drug_death`. The two non-drug rows (I250, C509) score 0; every
drug-poisoning row scores 1, including the psychostimulant row
(e.g. methamphetamine) that is not an opioid.

``` r

step1 <- flag_drug_deaths(resident_deaths, year = 2019L)
step1[, c("ucod", "f_records_all", "drug_death")]
#>   ucod f_records_all drug_death
#> 1  X42          T400          1
#> 2  X42     T401 T404          1
#> 3  X44          T402          1
#> 4  X42          T403          1
#> 5  X42          T404          1
#> 6  Y12          T406          1
#> 7  X40          T436          1
#> 8 I250          I250          0
#> 9 C509          C509          0
```

**Step 2.**
[`flag_opioid_deaths()`](https://mkiang.github.io/narcan/reference/flag_opioid_deaths.md)
adds `opioid_death`. It lights up only where a drug death *also* carries
an opioid T-code, so `X40` / `T436` stays 0.

``` r

step2 <- flag_opioid_deaths(step1, year = 2019L)
step2[, c("ucod", "f_records_all", "drug_death", "opioid_death")]
#>   ucod f_records_all drug_death opioid_death
#> 1  X42          T400          1            1
#> 2  X42     T401 T404          1            1
#> 3  X44          T402          1            1
#> 4  X42          T403          1            1
#> 5  X42          T404          1            1
#> 6  Y12          T406          1            1
#> 7  X40          T436          1            0
#> 8 I250          I250          0            0
#> 9 C509          C509          0            0
```

**Step 3.**
[`flag_opioid_types()`](https://mkiang.github.io/narcan/reference/flag_opioid_types.md)
adds the six subtype indicators plus `num_opioids` (and
`multi_opioids`). The polydrug row (`T401 T404`) now reads two distinct
opioids.

``` r

classified <- flag_opioid_types(step2, year = 2019L)
classified[, c("f_records_all", "opioid_death", "heroin_present",
               "other_synth_present", "num_opioids", "multi_opioids")]
#>   f_records_all opioid_death heroin_present other_synth_present num_opioids
#> 1          T400            1              0                   0           1
#> 2     T401 T404            1              1                   1           2
#> 3          T402            1              0                   0           1
#> 4          T403            1              0                   0           1
#> 5          T404            1              0                   1           1
#> 6          T406            1              0                   0           1
#> 7          T436            0              0                   0           0
#> 8          I250            0              0                   0           0
#> 9          C509            0              0                   0           0
#>   multi_opioids
#> 1             0
#> 2             1
#> 3             0
#> 4             0
#> 5             0
#> 6             0
#> 7             0
#> 8             0
#> 9             0
```

## The two ISW7 rules

The definitions nest. A **drug death** requires a drug-poisoning
underlying cause (X40-44, X60-64, X85, or Y10-14) *and* a drug T-code
(T36.0-T50.9). An **opioid death** is the strict subset of drug deaths
that also carry an opioid T-code (T40.0-T40.4 or T40.6). So a poisoning
with a non-opioid drug is a drug death but not an opioid death. Row
`X40` / `T436` (a psychostimulant, e.g. methamphetamine) is exactly that
edge case – `drug_death` is 1, `opioid_death` is 0.

Requiring the T-code makes narcan’s `drug_death` marginally stricter
than the CDC WONDER “drug overdose” count, which keys on the underlying
cause alone – about 0.1% fewer deaths, because narcan drops the few
poisoning-UCOD deaths that carry no drug T-code at all (see
[`?flag_drug_deaths`](https://mkiang.github.io/narcan/reference/flag_drug_deaths.md)).

``` r

classified[classified$ucod == "X40",
           c("ucod", "f_records_all", "drug_death", "opioid_death")]
#>   ucod f_records_all drug_death opioid_death
#> 7  X40          T436          1            0
```

## The opioid subtypes

Among opioid deaths,
[`flag_opioid_types()`](https://mkiang.github.io/narcan/reference/flag_opioid_types.md)
breaks out six specific T40 subtypes – `opium_present` (T40.0),
`heroin_present` (T40.1), `other_natural_present` (T40.2),
`methadone_present` (T40.3), `other_synth_present` (T40.4, the fentanyl
proxy), and `other_op_present` (T40.6). `unspecified_op_present` is the
residual for an opioid death where none of the six matched; for ICD-10
data (1999+) it is **always 0 by construction**, because every ICD-10
opioid T40 code falls into at least one of those six subtypes – it fires
only for the pre-1999 ICD-9 residual (code 965.0). If you want the share
of opioid deaths with an *unspecified* opioid type in modern data, the
column you want is `other_op_present` (T40.6, “other and unspecified
narcotics”), not the similarly named `unspecified_op_present`; see
[`vignette("unspecified-drug-deaths")`](https://mkiang.github.io/narcan/articles/unspecified-drug-deaths.md).
`num_opioids` counts how many distinct subtypes appear on the record,
and `multi_opioids` is 1 when `num_opioids > 1`. The polydrug row
(`T401 T404`) shows `num_opioids = 2`.

``` r

subtype_cols <- c(
    "opium_present", "heroin_present", "other_natural_present",
    "methadone_present", "other_synth_present", "other_op_present",
    "unspecified_op_present", "num_opioids"
)
classified[classified$opioid_death == 1, c("f_records_all", subtype_cols)]
#>   f_records_all opium_present heroin_present other_natural_present
#> 1          T400             1              0                     0
#> 2     T401 T404             0              1                     0
#> 3          T402             0              0                     1
#> 4          T403             0              0                     0
#> 5          T404             0              0                     0
#> 6          T406             0              0                     0
#>   methadone_present other_synth_present other_op_present unspecified_op_present
#> 1                 0                   0                0                      0
#> 2                 0                   1                0                      0
#> 3                 0                   0                0                      0
#> 4                 1                   0                0                      0
#> 5                 0                   1                0                      0
#> 6                 0                   0                1                      0
#>   num_opioids
#> 1           1
#> 2           2
#> 3           1
#> 4           1
#> 5           1
#> 6           1
```

## Matching `year` to the coding era

Every flagger dispatches on `year`. Data years before 1999 use ICD-9
logic; 1999 onward uses the ICD-10 rules shown here. Match `year` to the
data year of the records so the correct code list is applied – there is
no default era.

Counts are **not directly comparable across the 1999 ICD-9-to-ICD-10
revision**. NCHS documents that drug-poisoning death counts before and
after the revision require a comparability-ratio adjustment before they
can be joined into one trend – the numerator analog of the “not
comparable” caveat on the denominator schemes (see
[`vignette("population-denominators")`](https://mkiang.github.io/narcan/articles/population-denominators.md)).
Concatenating raw pre- and post-1999 counts produces an artifactual step
at the boundary.

## See also

- [`vignette("population-denominators")`](https://mkiang.github.io/narcan/articles/population-denominators.md)
  – attach a matching population to these flagged counts, the next step
  before computing any rate.
- [`vignette("getting-started")`](https://mkiang.github.io/narcan/articles/getting-started.md)
  – the full raw-data-to-rate pipeline and where this vignette fits.
- Related flags not covered here:
  [`flag_opioid_contributed()`](https://mkiang.github.io/narcan/reference/flag_opioid_contributed.md)
  (opioids as a contributory rather than underlying cause),
  [`flag_nonopioid_drug_deaths()`](https://mkiang.github.io/narcan/reference/flag_nonopioid_drug_deaths.md),
  and
  [`flag_od_intent()`](https://mkiang.github.io/narcan/reference/flag_od_intent.md)
  (unintentional / suicide / homicide / undetermined intent).
