# `narcan`

[![No Maintenance Intended](http://unmaintained.tech/badge.svg)](http://unmaintained.tech/)

An R package for working with [multiple cause of death micro-data](https://wonder.cdc.gov/mcd.html).

## Warning

**This package is not intended for public use.** It is occasionally maintained
for personal use only, so bugs may abound. User beware.

Development and maintenance are assisted by Claude (Anthropic).

## What it does

`narcan` implements the Injury Surveillance Workgroup (ISW7) definitions for
drug- and opioid-involved deaths in US multiple-cause-of-death (MCOD) data. A
drug death is a drug-poisoning underlying cause (ICD-10 X40-X44, X60-X64, X85,
Y10-Y14) together with a contributory poisoning T-code (T36-T50); opioid
involvement adds the opioid T-codes (T40.0-T40.4 and T40.6). The package also
covers the ICD-9 era (1979-1998), harmonizes race/Hispanic-origin and county
recodes across NCHS coding changes, and computes age-standardized rates.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("mkiang/narcan")
```

## Example

Flag drug- and opioid-involved deaths from a set of cause-of-death records:

``` r
library(narcan)

deaths <- data.frame(
  year = 2019,
  ucod = c("X42", "I250", "X44"),
  f_records_all = c("T401 T402", "I250", "T436")
)

deaths |>
  flag_drug_deaths(year = 2019) |>
  flag_opioid_deaths(year = 2019)
#>  year ucod f_records_all drug_death opioid_death
#>  2019  X42     T401 T402          1            1
#>  2019 I250          I250          0            0
#>  2019  X44          T436          1            0
```

The X42 death is drug- and opioid-involved (heroin, T40.1); the X44 death is a
drug poisoning but not an opioid (psychostimulant, T43.6); the I250 death is
neither.

Full function reference: <https://mkiang.github.io/narcan/>.
