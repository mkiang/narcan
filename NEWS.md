# narcan 0.3.0

## Modernized for current R and tidyverse

This release brings a long-dormant package up to date with modern R and
tidyverse conventions and fixes several correctness issues, while preserving the
existing analysis behavior. `R CMD check` is clean (0 errors, 0 warnings).

### Changed (behavior)

* **Minimum R is now 4.2** -- the package uses the native `|>` pipe internally.
* **The `flag_suicide_*` family gains a `year` argument and now warns on pre-1999
  (ICD-9) data** instead of silently returning all zeros. ICD-9 suicide coding is
  not yet implemented; the warning fires only when a year is determinable and
  `< 1999`.
* **`state_abbrev_to_fips()` now zero-pads** two-digit FIPS codes (e.g. `"06"` for
  California, not `"6"`), matching `add_county_fips()` and the NCHS convention.
* **`unite_records()` now errors on a year outside 1979-1998 / `>= 1999`** (for
  example a two-digit `datayear` such as `93`) instead of silently returning an
  unrelated object. Pass an explicit four-digit `year`.

### New

* The main data-consuming functions (`unite_records()`, `flag_drug_deaths()`,
  `flag_opioid_deaths()`, `flag_opioid_types()`, `flag_od_intent()`,
  `calc_asrate_var()`, `calc_stdrate_var()`, `add_pop_counts()`, `add_std_pop()`)
  now emit a plain **warning** when the first argument is not a data frame or is
  missing a required column, so a mistake surfaces by name rather than as a
  cryptic downstream error. These checks never abort.

### Internal

* Dependency calls deprecated or defunct in current dplyr were updated with no
  change in output: `funs()` -> `across()`, `mutate_at(vars())` -> `mutate()`,
  `one_of()` -> `any_of()`, and `group_by(add = TRUE)` -> `group_by(.add = TRUE)`.
* Converted internal code to the native `|>` pipe, modernized the rate/summary
  helpers' non-standard evaluation to `{{ }}` embracing, and replaced
  `tidyr::gather()` with `tidyr::pivot_longer()`.
* Removed the unused `purrr` dependency.

# narcan 0.2.1

## Coding-aware race/Hispanic recode functions

The recode/label helpers previously hardcoded a single coding scheme and applied
it to every year, silently mislabeling data for years where NCHS coding changed.
They are now year-aware. Values verified against the NCHS public-use mortality
file documentation.

### Changed (behavior)

* **`categorize_hspanicr(hspanicr_column, year = NULL)`** gains a `year` argument
  (a scalar or a vector aligned to the data column). It applies the 9-category
  scheme through 2020, returns `NA` for the reserved 2021 field, and applies the
  expanded 14-category (single-race, 1997 OMB) scheme from 2022. Values before
  1989 (not recorded) are `NA`. When `year` is omitted the pre-2022 9-category
  scheme is assumed **with a warning** -- existing calls keep working but should
  pass `year` to label 2022+ data correctly.
* **`remap_race(icd_df, year)`** now dispatches three ways: bridged detailed
  `race` through 2020 (unchanged), `NA` for the 2021 transition gap (bridged race
  dropped, single-race recodes not yet populated), and the single-race Race
  Recode 6 (`racer5`) from 2022 mapped to a non-colliding code space (101-106).
  The internal `.remap_race_1992_2015` helper is renamed `.remap_race_1992_2020`.
* **`categorize_race()`** labels the single-race codes 101-106 (`white_only`,
  `black_only`, `american_indian_only`, `asian_only`, `nhopi_only`,
  `multiracial`) in addition to the bridged codes; the factor levels adapt to the
  scheme(s) present, so pre-2021 output is unchanged.
* Bridged (<=2020) and single-race (2022+) race/Hispanic categories are **not
  comparable**; `remap_race()` and `categorize_race()` warn when the single-race
  path is used, and the two must not be chained into a single trend.

### New

* **`import_mcod_fwf()` now guarantees a canonical `year` column** (from its
  `year` argument), so downstream year dispatch works on every era including
  stacked multi-year data. 1979-1995 files retain their original `datayear`
  column as well.
* `.extract_year()` falls back to `datayear` (used by 1979-1995 files) when no
  `year` column is present.

### Notes

* Rates for 2021+ single-race deaths need single-race population denominators;
  `add_pop_counts()` joins bridged-race `pop_est` only (discontinued by NCHS after
  Vintage 2020). See `?add_pop_counts`. Single-race denominators are future work.
* New `testthat` coverage for the recode functions is built from a small random
  sample of **real** public MCOD data spanning every coding era.

# narcan 0.2.0

## Byte-verified fixed-width layouts (1979-2024)

The MCOD fixed-width dictionaries were re-verified against the raw NCHS bytes for
every year (public 1979-2024 and restricted 1989-2024), not just the NBER Stata
dictionaries. narcan's existing positions were found to be **highly accurate**;
this release makes a small set of corrections and adds public-use support.

### New

* **`mcod_public_fwf_dicts`** -- a public-use tier dictionary, and
  **`import_mcod_fwf(file, year, tier = c("restricted", "public"))`**, a single
  exported importer for both tiers. The public importer keeps restricted-only /
  suppressed columns (sub-state geography and record type from 2005, certifier,
  tobacco, pregnancy) as all-`NA` so public and restricted output are
  column-compatible. Public effective record length by year: 440 (1979-2002),
  488 (2003-2012), 490 (2013-2019), 817 (2020-2024).
* **`add_coded_occupation(df, year)`** -- harmonizes coded occupation/industry across
  the two non-comparable schemes (3-digit Census 1985-1999; 4-digit NCHS+NIOSH 2020+) into
  standard `occ_coded`/`ind_coded`/`occ_recode`/`ind_recode` columns plus `occ_scheme` and an
  `occ_available` flag, so researchers need not know byte positions, era, or tier. The 4-digit
  codes reach the public file in 2020 but the restricted file only in 2021 (identical from 2021).
* Coverage extended to data years **2023 and 2024** (both tiers).
* `cdc_dict` extended through the latest public-use year (**2024**); `.download_mcod_fwf()`
  now uses the CDC HTTPS endpoint (the old `ftp://` host was decommissioned).
* The dictionaries are now built from reviewed source CSVs
  (`data-raw/fwf_layouts/*.csv`) by a network-free assembly script that writes
  the exported and internal copies in sync.

### Corrections (restricted tier)

* **`hspanicr` widened from 1 byte (@488) to 2 bytes (@487-488) for 2022+.** This
  is the only change that alters parsed values: reading a single byte truncated
  the 14-category Hispanic-origin/race recode to ~10 units-digit values (e.g.
  Mexican `01` collided with non-Hispanic Asian `11`). **If you parsed 2022+
  restricted data with narcan < 0.2.0, re-import to recover the full recode.**
* **`racer40` (@489-490) is now declared for restricted 2003-2011** as a
  documented-but-empty field, making the declared record length faithful to the
  true 490-byte record. This adds an all-`NA` `racer40` column to those years'
  output; no other values change.

### Notes (no code change; positions were already correct)

* narcan already carried `racer40` from data year 2012 with record length 490 --
  NCHS documentation that dates it to 2018 is wrong for the data.
* `read_fwf()`'s newline-delimited read already handles 2005+ public geography
  suppression and the 1980 variable-length public file correctly.
* Some columns keep their NBER names but change meaning across an era boundary --
  see `?mcod_fwf_dicts`: `ucr130` is all-ages in 1999-2001 (infant-only from
  2002); `racer5`@450 is bridged Race Recode 5 through 2020 and single-race Race
  Recode 6 from 2022.

### Internal

* Removed the stale `data-raw/making_restricted_dicts.R` (it wrote unrelated
  objects to `R/sysdata.rda` and would have clobbered the dictionaries if re-run).
* Added a `testthat` (edition 3) suite: dictionary integrity (types, monotonic
  positions, `max(end)` equals the expected record length), public/restricted
  column parity, a pre-2022 restricted snapshot, and importer round-trip / parity
  on synthetic fixtures.
