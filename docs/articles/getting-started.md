# Getting started with narcan

narcan turns raw US multiple-cause-of-death (MCOD) micro-data into drug-
and opioid-overdose death counts and age-standardized rates. It
implements the Injury Surveillance Workgroup (ISW7; CSTE/CDC) case
definitions across both the ICD-9 (1979-1998) and ICD-10 (1999+) eras,
and harmonizes the race, Hispanic-origin, and county recodes that NCHS
changed over the years. This vignette maps the whole package; each step
links to a dedicated vignette.

``` r

library(narcan)
```

## The pipeline

Most analyses follow the same four steps, from a raw NCHS file to a
rate.

| Step | Functions | Vignette |
|----|----|----|
| 1\. Import | [`import_mcod_fwf()`](https://mkiang.github.io/narcan/reference/import_mcod_fwf.md), [`unite_records()`](https://mkiang.github.io/narcan/reference/unite_records.md) | this vignette (below) |
| 2\. Flag | [`flag_drug_deaths()`](https://mkiang.github.io/narcan/reference/flag_drug_deaths.md), [`flag_opioid_deaths()`](https://mkiang.github.io/narcan/reference/flag_opioid_deaths.md), [`flag_opioid_types()`](https://mkiang.github.io/narcan/reference/flag_opioid_types.md) | [`vignette("classifying-overdose-deaths")`](https://mkiang.github.io/narcan/articles/classifying-overdose-deaths.md) |
| 3\. Denominators | [`add_pop_counts()`](https://mkiang.github.io/narcan/reference/add_pop_counts.md) | [`vignette("population-denominators")`](https://mkiang.github.io/narcan/articles/population-denominators.md) |
| 4\. Rates | [`add_std_pop()`](https://mkiang.github.io/narcan/reference/add_std_pop.md), [`calc_stdrate_var()`](https://mkiang.github.io/narcan/reference/calc_stdrate_var.md) | [`vignette("age-standardized-rates")`](https://mkiang.github.io/narcan/articles/age-standardized-rates.md) |

Further vignettes branch off this spine:
[`vignette("demographic-recodes")`](https://mkiang.github.io/narcan/articles/demographic-recodes.md)
(the year-aware age/sex/race recodes that produce the columns above),
[`vignette("hispanic-origin")`](https://mkiang.github.io/narcan/articles/hispanic-origin.md)
(Hispanic-origin stratification), and
[`vignette("geography-fips")`](https://mkiang.github.io/narcan/articles/geography-fips.md)
(sub-national geography). A measurement caveat – how the share of
*unspecified* drug deaths shifts trends over time – is in
[`vignette("unspecified-drug-deaths")`](https://mkiang.github.io/narcan/articles/unspecified-drug-deaths.md).
To see every step run on a real file,
[`vignette("real-data-end-to-end")`](https://mkiang.github.io/narcan/articles/real-data-end-to-end.md)
takes the public-use 2004 data all the way to an age-standardized opioid
rate.

## Getting the data

Public-use MCOD micro-data is distributed by NCHS and mirrored by NBER;
the restricted All-County files require an NCHS data-use agreement
(DUA). narcan can fetch a public-use year for you:

``` r

# Downloads the NBER public-use mirror into `download_dir`.
download_mcod_csv(2019, download_dir = "raw_data")   # or download_mcod_dta()
```

To read a raw fixed-width file (public or restricted), use
[`import_mcod_fwf()`](https://mkiang.github.io/narcan/reference/import_mcod_fwf.md),
which applies narcan’s byte-verified column dictionary for the given
year and tier:

``` r

raw <- import_mcod_fwf("mort2019us.dat", year = 2019, tier = "public")
```

The two tiers share the within-record layout; the public tier blanks
sub-state geography (from 2005) and a few certifier-entered items, which
[`import_mcod_fwf()`](https://mkiang.github.io/narcan/reference/import_mcod_fwf.md)
returns as all-`NA` so public and restricted output are
column-compatible.

**No restricted-data agreement yet?** The public-use file for **2004**
is the last public year that still carries county geography (2005 onward
suppress it).
[`import_mcod_fwf()`](https://mkiang.github.io/narcan/reference/import_mcod_fwf.md)
orders its output to the restricted column layout for every tier, so
reading the 2004 public file already gives you a restricted-shaped frame
with county of residence and occurrence – a DUA-free stand-in for
developing county-level code before you obtain the restricted All-County
files:

``` r

raw04 <- import_mcod_fwf("mort2004us.dat", year = 2004, tier = "public")
```

Two caveats. On the public file, county FIPS are populated only for
counties with a population of at least 100,000; smaller
(disproportionately rural) counties collapse to a residual code, so this
stand-in exercises large-county behavior only. And `tier = "restricted"`
adds nothing for 2004 – the single field it would add (`racer40`) sits
past the end of the public record and returns all-`NA`.

## From raw records to the flag pipeline

The flaggers key on two fields: the underlying cause (`ucod`) and a
single string of all contributory cause codes (`f_records_all`). A real
MCOD file stores the contributory codes across many separate `record_*`
columns, so `f_records_all` is **derived**, not read directly –
[`unite_records()`](https://mkiang.github.io/narcan/reference/unite_records.md)
builds it:

``` r

records <- unite_records(raw, year = 2019)

# `records` now carries `ucod` + the collapsed `f_records_all`, ready to flag:
flagged <- records |>
    flag_drug_deaths(year = 2019) |>
    flag_opioid_deaths(year = 2019)
```

From here you are at the start of
[`vignette("classifying-overdose-deaths")`](https://mkiang.github.io/narcan/articles/classifying-overdose-deaths.md),
which walks the flag pipeline step by step. To run unite + the
drug/opioid/type/intent flaggers in a single call, use the
[`flag_all_deaths()`](https://mkiang.github.io/narcan/reference/flag_all_deaths.md)
convenience wrapper.

## The columns narcan expects

Downstream functions read a handful of raw (or lightly recoded) MCOD
columns. This is the minimal set; each vignette introduces the ones it
needs.

| Column | Meaning | Raw or derived |
|----|----|----|
| `year` | data year (4-digit; 1979-1995 files use a 2-digit `datayear`) | raw |
| `ucod` | underlying cause of death (ICD code) | raw |
| `record_1`, `record_2`, … | contributory cause-code columns | raw |
| `f_records_all` | space-joined contributory codes | derived ([`unite_records()`](https://mkiang.github.io/narcan/reference/unite_records.md)) |
| `restatus` | residency status (1-3 = US resident) | raw |
| `age` | age (see [`remap_age()`](https://mkiang.github.io/narcan/reference/remap_age.md) / [`categorize_age_5()`](https://mkiang.github.io/narcan/reference/categorize_age_5.md)) | raw / recoded |
| `sex` | sex (see [`categorize_sex()`](https://mkiang.github.io/narcan/reference/categorize_sex.md)) | raw / recoded |
| `race` | race (see [`categorize_race()`](https://mkiang.github.io/narcan/reference/categorize_race.md); era-dependent) | raw / recoded |
| `hspanicr` | Hispanic-origin recode (see [`categorize_hispanic_origin()`](https://mkiang.github.io/narcan/reference/categorize_hispanic_origin.md)) | raw |
| `countyrs` / `countyoc` | county of residence / occurrence | raw |

## Next steps

Start with
[`vignette("classifying-overdose-deaths")`](https://mkiang.github.io/narcan/articles/classifying-overdose-deaths.md)
(the flag step), then
[`vignette("population-denominators")`](https://mkiang.github.io/narcan/articles/population-denominators.md)
and
[`vignette("age-standardized-rates")`](https://mkiang.github.io/narcan/articles/age-standardized-rates.md)
to turn counts into rates.
[`vignette("real-data-end-to-end")`](https://mkiang.github.io/narcan/articles/real-data-end-to-end.md)
runs that whole path on a real public-use file. Branch to
[`vignette("demographic-recodes")`](https://mkiang.github.io/narcan/articles/demographic-recodes.md)
for the age/sex/race recoders,
[`vignette("hispanic-origin")`](https://mkiang.github.io/narcan/articles/hispanic-origin.md)
to stratify by Hispanic origin, or
[`vignette("geography-fips")`](https://mkiang.github.io/narcan/articles/geography-fips.md)
for sub-national work;
[`vignette("unspecified-drug-deaths")`](https://mkiang.github.io/narcan/articles/unspecified-drug-deaths.md)
covers a measurement caveat.

## A note on this documentation

Every runnable chunk in these vignettes uses small **synthetic or
bundled** data, never restricted records, so they build without a
data-use agreement or a network connection. The download/import chunks
above are shown with `eval = FALSE` because they need a real file; swap
in your own path to run them.
