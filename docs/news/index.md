# Changelog

## narcan 0.5.1

### New features – single-race backfill to 2000 + SEER-uniform bridged denominators

- **Single-race denominators extended back to 2000.**
  `pop_singlerace_full` (national, bundled) now spans **2000-2024**,
  backfilling the 0.5.0 tables (which covered 2020-2024). State and
  county backfills ship as Release assets. The 0.5.0
  `pop_singlerace`/`pop_singlerace_state` (2020-2024) are **frozen
  byte-for-byte**; the backfill is additive and its 2020-2024 slice is
  identical to the frozen tables.
- **SEER-uniform bridged-race denominators, 1969-2024.** New
  `pop_bridged` (national, bundled) plus state/county Release assets
  give a single, internally consistent bridged-race series from the SEER
  U.S. Population Data. Unlike the legacy `pop_est` (pieced-together
  vintages, stops at 2020), this one series covers 1969-2024 at
  national/state/county. It is **era-ragged**: SEER resolves AIAN/API
  and Hispanic origin only from 1990 (pre-1990 is white/black/other
  only), so the bridged scheme requires `year` and validates the race
  set per row’s era.
- **[`add_pop_counts()`](https://mkiang.github.io/narcan/reference/add_pop_counts.md)
  gains `race_scheme = "bridged"`** alongside `"legacy"` (default) and
  `"single"`. Both strict schemes guarantee no silent `NA` denominator;
  a request that reaches a year outside a scheme’s coverage is a hard
  error, not a silent empty result. Single-race requests routed to a
  pre-2020 year automatically use the backfill; 2020-2024-only requests
  stay on the dependency-free bundled tables.
- **[`get_pop_state()`](https://mkiang.github.io/narcan/reference/get_pop_state.md)/[`get_pop_county()`](https://mkiang.github.io/narcan/reference/get_pop_county.md)
  gain the bridged scheme** and honor the backfill (pass pre-2020
  `years` to reach 2000-2024);
  [`get_pop_state()`](https://mkiang.github.io/narcan/reference/get_pop_state.md)
  gains a `parquet=` argument. `download_pop_data(scheme = "bridged")`
  fetches the bridged parquets;
  [`pop_sources()`](https://mkiang.github.io/narcan/reference/pop_sources.md)
  lists every single-race and bridged dataset.
- **New vignettes:** `classifying-overdose-deaths` (ISW7 drug/opioid
  flagging), `age-standardized-rates` (an end-to-end age-standardized
  synthetic-opioid rate by sex, US residents), `population-denominators`
  (choosing among the three schemes; supersedes `single-race-rates`),
  `geography-fips` (FIPS harmonization, public geography 1999-2004), and
  `unspecified-drug-deaths` (the specificity problem over time).

### Bug fixes (surfaced by the pre-delivery review)

A standing pre-delivery review (seven Opus + Sonnet-5 pairs, including
passes over older, less-vetted code) found two pre-existing correctness
bugs, now fixed. The pre-fix behavior is reproducible from the `v0.5.0`
tag.

- **[`unite_records()`](https://mkiang.github.io/narcan/reference/unite_records.md)
  auto-cleans raw ICD-9 data, so the `flag_*` pipeline is correct on
  ICD-9-era records (data years 1979-1998) without a manual
  [`clean_icd9_data()`](https://mkiang.github.io/narcan/reference/clean_icd9_data.md)
  step.** For the ICD-9 era it now runs the idempotent
  [`clean_icd9_data()`](https://mkiang.github.io/narcan/reference/clean_icd9_data.md)
  internally before collapsing the record columns. Previously, calling
  the documented pipeline
  ([`unite_records()`](https://mkiang.github.io/narcan/reference/unite_records.md)
  -\>
  [`flag_drug_deaths()`](https://mkiang.github.io/narcan/reference/flag_drug_deaths.md)/[`flag_opioid_deaths()`](https://mkiang.github.io/narcan/reference/flag_opioid_deaths.md)/
  [`flag_opioid_types()`](https://mkiang.github.io/narcan/reference/flag_opioid_types.md))
  on a *raw* ICD-9 frame silently returned all-zero drug/opioid flags
  (mis-formatted E-codes and nature-of-injury codes missed the ICD-9
  regex) or errored on the `rniflag_`-named nature-of-injury columns
  (1991-1995 files). **Blast radius:** pre-1999 analyses that did not
  already call
  [`clean_icd9_data()`](https://mkiang.github.io/narcan/reference/clean_icd9_data.md)
  first – their flag counts change from wrong to correct.
  Already-cleaned pipelines are unchanged (the cleaner is idempotent).
- **[`add_coded_occupation()`](https://mkiang.github.io/narcan/reference/add_coded_occupation.md)
  returns type-stable, zero-padded codes.** `occ_coded`/`ind_coded` are
  now zero-padded *character* in both eras. Previously the 1982-1999
  Census (3-digit) scheme returned *numeric* codes with leading zeros
  dropped (e.g. `7` for occupation `"007"`), which broke 3-digit
  crosswalks and made a `bind_rows()` of a pre-2000 result with a 2020+
  NIOSH (character) result error on the type clash.

### Guards

- **The strict-scheme join now asserts the population slice is unique on
  its finest cell before aggregating**, so a corrupted or duplicated
  denominator asset can no longer silently double a rate’s denominator
  (the many-to-one join could not catch this on its own). Year handling
  in the accessors is factor-safe.

### Notes

- The bundled population manifest now points the single-race county
  asset at the 2000-2024 backfill (superseding the 0.5.0 2020-2024
  asset); the 0.5.0 asset remains available at the `v0.5.0` tag for
  reproducing 0.5.0 rates.
- Legacy bridged-race (`"legacy"`), SEER bridged (`"bridged"`), and
  single-race (`"single"`) denominators are **not comparable** and must
  not be chained into one trend. The bridged Hispanic-origin dimension
  ships now, but the death-side Hispanic join is still deferred to a
  later release.
- [`download_pop_data()`](https://mkiang.github.io/narcan/reference/download_pop_data.md)
  dropped its `years` argument, which was reserved and never functional
  (no code path consumed it); the source/asset pull is otherwise
  unchanged. This is the only non-additive signature change in 0.5.1.
- Apart from that non-functional `years` argument, nothing was renamed
  or removed; all new datasets and arguments are additive and the frozen
  `pop_est`/`pop_singlerace`/`pop_singlerace_state` are unchanged.

## narcan 0.5.0

### New features – single-race population denominators (2020-2024)

- **Single-race denominators for 2022+ deaths.** From data year 2022
  NCHS codes race with the single-race (OMB 1997) scheme;
  [`categorize_race()`](https://mkiang.github.io/narcan/reference/categorize_race.md)
  labels those deaths
  `white_only`/`black_only`/`american_indian_only`/`asian_only`/
  `nhopi_only`/`multiracial` (codes 101-106). This release adds matching
  Census Population Estimates Program (Vintage 2024) denominators for
  2020-2024 so those deaths get correct rates. Bundled: `pop_singlerace`
  (national) and `pop_singlerace_state` (state). County estimates are
  too large to bundle and are fetched on demand (see below). Each
  dataset also carries a `hispanic_origin` dimension.
- **[`add_pop_counts()`](https://mkiang.github.io/narcan/reference/add_pop_counts.md)
  gains `race_scheme`.** `race_scheme = "legacy"` (the **default**)
  joins the frozen bridged-race `pop_est` and reproduces existing
  bridged-race rates *byte-for-byte*. `race_scheme = "single"` joins the
  new single-race denominators. The single scheme guarantees no silent
  `NA` denominator: out-of-domain `age`/`sex`/`race` values and
  unmatched keys are hard errors, and passing single-race labels under
  the default scheme errors with a pointer to `race_scheme = "single"`.
  Geography is routed by `by_vars` membership – add
  `state_fips`/`county_fips` for sub-national denominators. The
  `"total"` (race), `"both"` (sex), and `"all"` (Hispanic origin)
  aggregate tokens are synthesized on demand.
- **New accessors
  [`get_pop_state()`](https://mkiang.github.io/narcan/reference/get_pop_state.md)
  and
  [`get_pop_county()`](https://mkiang.github.io/narcan/reference/get_pop_county.md)**
  return population rows for descriptive use, with the Hispanic-origin
  dimension exposed.
- **[`download_pop_data()`](https://mkiang.github.io/narcan/reference/download_pop_data.md)**
  fetches data too large to bundle. By default it fetches the
  analysis-ready county parquet from the tagged GitHub release and
  verifies its checksum; `raw = TRUE` fetches the original Census source
  files verbatim (the same pull the package’s own build uses), so the
  processed data can be reproduced from scratch.
  [`pop_sources()`](https://mkiang.github.io/narcan/reference/pop_sources.md)
  prints the provenance manifest (source, vintage, coverage, delivery)
  for every dataset.
- **New vignette** `single-race-rates` walks through an `asian_only`
  age-standardized rate end to end.

### Bug fixes

- **[`calc_stdrate_var()`](https://mkiang.github.io/narcan/reference/calc_stdrate_var.md)
  age-standardized variance corrected for cells with a missing
  age-specific rate.** When a stratum’s rate was `NaN` (a legitimate
  `pop == 0` cell) or its weight was `NA`, the standardized rate
  renormalized over the surviving strata but the variance did not, so
  the reported variance (and confidence interval) was too small. The
  rate and variance now drop the same strata and renormalize
  identically. **Complete-data rates are unchanged (byte-for-byte);
  complete-data variances are numerically unchanged** (they differ by at
  most a few ULP from reordered floating-point operations). Only
  estimates with an empty/dropped stratum change materially (their
  variance was previously understated). An `NA` weight now drops that
  stratum from the rate too (previously it made the whole rate `NA`).
- **[`add_county_fips()`](https://mkiang.github.io/narcan/reference/add_county_fips.md)
  no longer silently misassigns state FIPS.** A numeric `county_vector`
  (leading zeros already lost) is now refused with a clear error instead
  of parsing e.g. Alabama county 01001 as state 10. A frame whose
  per-row `year` straddles the 2002/2003 NCHS-\>FIPS boundary now
  resolves the coding scheme separately per era, so a mixed-era frame no
  longer decodes the minority era with the wrong scheme.
- **[`clean_icd9_data()`](https://mkiang.github.io/narcan/reference/clean_icd9_data.md)
  is now idempotent.** Cleaning an already-cleaned frame no longer NAs
  external-cause (E-code) UCODs; the record prefixer likewise never
  drops an in-range record to `NA` on a missing nature-of-injury flag.

### Minor changes

- [`calc_asrate_var()`](https://mkiang.github.io/narcan/reference/calc_asrate_var.md)
  now emits a warning when any cell has `pop == 0` (its rate is
  undefined). This is a diagnostic only – the numeric output is
  unchanged, so existing rate values are unaffected. Zero-population
  cells are common in fine single-race county strata.
- [`add_std_pop()`](https://mkiang.github.io/narcan/reference/add_std_pop.md)
  warns when the chosen standard’s age granularity does not match the
  data (e.g. a single-year standard joined to 5-year bins), which would
  otherwise misweight standardized rates silently.
- [`remap_race()`](https://mkiang.github.io/narcan/reference/remap_race.md)
  and
  [`remap_age()`](https://mkiang.github.io/narcan/reference/remap_age.md)
  now warn when an input code falls outside the known set for its era
  (previously silently `NA`), matching the loud unmatched- code warnings
  in
  [`add_county_fips()`](https://mkiang.github.io/narcan/reference/add_county_fips.md).
- Documentation corrected: `std_pops` (1015 rows; five SEER standards
  s13-s17 are unlabeled) and `st_fips_map` (`fips`/`nchs` are numeric).
  `download_natality_ ascii()` now fetches over HTTPS (the CDC `ftp://`
  host was decommissioned).

### Notes

- Bridged-race (`"legacy"`, 2020 and earlier) and single-race
  (`"single"`, 2022+) denominators are **not comparable** and must not
  be chained into one trend. The frozen `pop_est` is unchanged; all new
  datasets and arguments are additive (nothing was renamed or removed).
- The Hispanic-origin dimension ships in the new denominator data now,
  but the death-side Hispanic join is deferred to a later release; the
  death-side join is currently pinned to all-origin denominators.
- narcan’s existing by-race rates for 2020 and earlier pair bridged-race
  death counts with single-race population estimates, which understates
  the denominator (most for smaller groups), so those rates run slightly
  high. A future release will add a bridged-race denominator series
  consistent across 1969-2024; for coherent single-race by-race rates
  from 2020 on, use the new single-race path.

## narcan 0.4.2

### Bug fixes

- **`pop_est` no longer contains the spurious `year == 420` block.** The
  bundled data carried an extra 216-row year labeled `420` – an
  alternate-vintage copy of the 2020 estimates whose year field was
  mangled during the original build (every cell is within ~1.2% of the
  real 2020 block; the legitimate 2020 data are unchanged). The block is
  removed; `pop_est` now spans exactly 1979-2020 (9072 rows). No
  legitimate year or cell changed value. The data builder now asserts
  the year range so a future rebuild cannot reship the artifact.
- **`pop_est` documentation corrected.** The help page said 1979-2015 /
  7992 rows; it now reads 1979-2020 / 9072 rows.

## narcan 0.4.1

### New features (0.4-P4)

- **[`flag_opioid_types()`](https://mkiang.github.io/narcan/reference/flag_opioid_types.md)
  and the six opioid-subtype flags gain `opioid_deaths_only` (default
  `TRUE`).** The default is unchanged – a type is flagged only for
  opioid deaths. With `FALSE`, an opioid *type* is flagged wherever its
  code appears in the contributory causes, even when the death is not an
  opioid death under the ISW7 combined rule; the caller is then expected
  to `filter(opioid_death == 1)` themselves (an opioid in a contributory
  cause does not make the death an opioid death). Resolves issue
  [\#2](https://github.com/mkiang/narcan/issues/2). `num_opioids` /
  `unspecified_op_present` stay coherent under `FALSE` (the residual
  keys off an “any opioid present” indicator, so it never fires on a
  non-opioid row).
- **[`categorize_sex()`](https://mkiang.github.io/narcan/reference/categorize_sex.md)
  and
  [`categorize_female()`](https://mkiang.github.io/narcan/reference/categorize_female.md)**
  – era-aware sex recodes. NCHS codes sex numerically (`1`/`2`) through
  2002 and as characters (`"M"`/`"F"`) from 2003; these map either
  scheme to `"male"`/`"female"`/`NA` (matching the `sex` labels in
  `pop_est`) and to `1`/`0`/`NA`, respectively. Resolves issue
  [\#11](https://github.com/mkiang/narcan/issues/11).
- **[`remap_age()`](https://mkiang.github.io/narcan/reference/remap_age.md)**
  – converts the raw unit-coded NCHS detail-age field (`age`) to age in
  completed years in a new `age_years` column, dispatching on the 2003
  encoding change; sub-year ages (months/weeks/days/hours/minutes)
  collapse to `0` and not-stated ages to `NA`. Resolves issue
  [\#15](https://github.com/mkiang/narcan/issues/15).
- **[`flag_all_deaths()`](https://mkiang.github.io/narcan/reference/flag_all_deaths.md)**
  – a convenience wrapper that runs the canonical pipeline
  (`unite_records` -\> `flag_drug_deaths` -\> `flag_opioid_deaths` -\>
  `flag_opioid_types` -\> `flag_od_intent`) in one call, resolving the
  data year once. Optional `types`/`intent`/`clean_icd9` toggles.

### Second-pass correctness fixes (0.4-P2b)

A second, exhaustive multi-agent review of the 0.4.0 code (weighted
toward the areas the first pass rated “clean,” and toward the 0.4.0
fixes themselves) found several correctness issues the first pass missed
– one of them introduced by a 0.4.0 fix. Point estimates on canonical
national data are essentially unchanged; the behavior changes below are
narrow. The 0.4.0 behavior is reproducible from the `v0.4.0` tag.

#### Breaking changes

- **[`add_county_fips()`](https://mkiang.github.io/narcan/reference/add_county_fips.md)
  gains `year` and `scheme` arguments and resolves the state-coding
  scheme deterministically.** NCHS mortality files code state as NCHS
  numeric codes through 2002 and as 2-letter postal abbreviations from
  2003; the numeric NCHS codes overlap FIPS but mean different states
  (NCHS `"06"` is Colorado, FIPS California). The function now picks the
  scheme from `year` (a scalar, or a `year` column on the data). When no
  year is available it guesses from the codes and **warns loudly** on an
  ambiguous numeric code instead of silently guessing FIPS (the 0.4.0
  subset-detection fix could resolve an isolated ambiguous code to the
  wrong state). Pass `scheme=` to force a scheme.
- **[`add_county_fips()`](https://mkiang.github.io/narcan/reference/add_county_fips.md)
  maps the ambiguous NCHS code 62 to `NA` (with a warning) instead of
  aborting.** NCHS 62 is both American Samoa and the Northern Mariana
  Islands; the 0.4.0 `relationship = "many-to-one"` join errored on the
  whole batch if any 62 record was present. Those rows now become `NA`
  state FIPS and the rest of the batch proceeds.
- **[`flag_od_intent()`](https://mkiang.github.io/narcan/reference/flag_od_intent.md)
  gates every intent flag on `drug_death == 1`.** A poisoning UCOD with
  no contributory T-code (not a drug death under the combined rule) now
  yields all-zero intents (`"not_overdose"` after
  [`label_od_intent()`](https://mkiang.github.io/narcan/reference/label_od_intent.md)),
  matching the
  [`flag_drug_deaths()`](https://mkiang.github.io/narcan/reference/flag_drug_deaths.md)
  definition. Previously intent was assigned from the UCOD alone.
  Real-data effect is negligible (a poisoning UCOD essentially always
  co-occurs with a qualifying T-code).
- **A two-digit `datayear` is normalized to its four-digit year.**
  [`.extract_year()`](https://mkiang.github.io/narcan/reference/dot-extract_year.md)
  (used by
  [`remap_race()`](https://mkiang.github.io/narcan/reference/remap_race.md),
  the `flag_*` family, and
  [`unite_records()`](https://mkiang.github.io/narcan/reference/unite_records.md))
  maps a 1979-1995 `datayear` such as `85` to `1985`. As a result the
  `flag_*` family now correctly dispatches a `datayear`-coded ICD-9 file
  to the ICD-9 branch, rather than erroring on the two-digit value
  (superseding the 0.4.0 behavior). An explicit two-digit `year`
  argument still errors.
- **[`add_coded_occupation()`](https://mkiang.github.io/narcan/reference/add_coded_occupation.md)
  recognizes the 3-digit occupation/industry scheme from data year
  1982** (was 1985). The byte-verified dictionary carries real,
  non-suppressed `occup`/`industry` from 1982, so 1982-1984 records were
  being silently dropped to `occ_available = FALSE`.

#### Fixed

- [`calc_asrate_var()`](https://mkiang.github.io/narcan/reference/calc_asrate_var.md)
  returns variance `0` (not `NaN`) for a zero-death cell. The variance
  is now `deaths * (1e5 / pop)^2` rather than the algebraically
  identical `rate^2 / deaths`, which was `0/0` when `deaths == 0`.
  Age-specific rate CIs for zero-count strata (ubiquitous in stratified
  data) were `NaN`; standardized rates were already shielded by `na.rm`.
- [`add_county_fips()`](https://mkiang.github.io/narcan/reference/add_county_fips.md)
  returns `NA` for a missing county code instead of the literal string
  `"NANA"`, and raises a clean error when every state code is missing
  (previously it silently produced `"NANA"`).
- [`remap_race()`](https://mkiang.github.io/narcan/reference/remap_race.md)
  errors on an impossible data year instead of emitting a bare
  `"Invalid year"` warning and passing raw, unmapped race codes through.
- [`state_abbrev_to_fips()`](https://mkiang.github.io/narcan/reference/state_abbrev_to_fips.md)
  maps an unrecognized or wrong-case abbreviation to `NA` with a
  warning, instead of returning it unchanged to fail a downstream join
  silently.
- [`unite_records()`](https://mkiang.github.io/narcan/reference/unite_records.md)
  strips a leading `"NA"` token (not only interior/trailing ones) when
  collapsing the record columns.

#### Guards / warnings

- [`calc_stdrate_var()`](https://mkiang.github.io/narcan/reference/calc_stdrate_var.md)
  warns when a multi-year frame is passed without `year` in the grouping
  (which would collapse all years into one rate) and when
  standardization weights are `NA` or sum to zero; the `...`
  documentation now states that grouping is not added automatically.
- [`summarize_binary_columns()`](https://mkiang.github.io/narcan/reference/summarize_binary_columns.md)
  warns when a non-binary column would be summed as a flag, and sums
  with `na.rm = TRUE` (warning when a flag column has `NA`s so a flag
  total may differ from `deaths`).

## narcan 0.4.0

### Verified-review correctness fixes (0.4-P2)

Fixes correctness issues surfaced by a systematic,
primary-source-anchored review of the ISW7 flag logic and the
geography/rate machinery. Point estimates for canonical NCHS data are
essentially unchanged; the behavior changes below are narrow. The
pre-fix state is tagged `v0.3.0` for reproducibility.

#### Breaking changes

- **[`add_county_fips()`](https://mkiang.github.io/narcan/reference/add_county_fips.md)
  errors on an ambiguous NCHS state code instead of silently duplicating
  rows.** NCHS code 62 maps to both American Samoa and the Northern
  Mariana Islands in `st_fips_map`, so an NCHS-coded “62” record
  previously fanned into two output rows. The NCHS join now uses
  `relationship = "many-to-one"`. Real-world impact is nil (code 62 does
  not appear in national MCOD files; public-MCOD-anchor estimate). Now
  requires `dplyr (>= 1.1.0)`.
- **[`calc_stdrate_var()`](https://mkiang.github.io/narcan/reference/calc_stdrate_var.md)
  renormalizes the age-standardized variance** by the weights actually
  present. Previously `sum(w^2 * var)` was correct only when the weights
  summed to 1; if age bins were dropped upstream the reported variance
  was under-stated (the point rate, already renormalized by
  [`weighted.mean()`](https://rdrr.io/r/stats/weighted.mean.html), is
  unchanged). Reported variances/CIs change ONLY for analyses passing
  incomplete age bins (e.g. county-level sparse-bin standardized rates);
  complete-bin analyses are unaffected.
- **The `flag_*` family errors on a 2-digit `datayear` or a 4-digit year
  before 1979** (shared
  [`.dispatch_era()`](https://mkiang.github.io/narcan/reference/dot-dispatch_era.md)
  guard) instead of silently routing the record into the ICD-10 branch.
  Valid 4-digit years (1979+) are unaffected.
- **`.regex_drug_icd10()` no longer matches T51-T59** (non-medicinal
  toxic effects); the drug T-code range is now T36.0-T50.9 as intended.
  Effect on `drug_death` counts is negligible: 8-26 records per year
  (\<= 0.07%) across public data years 2005-2023 (public-MCOD-anchor
  estimate).
- **`.regex_drug_icd9()` no longer matches the unassigned E859**; the
  accidental E-code range is now E850-E858. No effect on real data: E859
  is unassigned in WHO ICD-9 (zero E859 records in 1998 public data;
  public-MCOD-anchor estimate).

#### Fixed

- [`add_county_fips()`](https://mkiang.github.io/narcan/reference/add_county_fips.md)
  detects the state-coding scheme (postal / NCHS / FIPS) by subset
  membership, so it works on a single state or filtered batch instead of
  requiring the entire national code space; an unrecognized scheme
  raises an informative error.
- [`add_pop_counts()`](https://mkiang.github.io/narcan/reference/add_pop_counts.md)
  warns when join keys have no match in `pop_est` (previously a silent
  NA population) and errors early on a pre-existing `pop` column;
  [`add_std_pop()`](https://mkiang.github.io/narcan/reference/add_std_pop.md)
  errors early on a pre-existing `pop_std`/`unit_w` column.
- [`flag_od_intent()`](https://mkiang.github.io/narcan/reference/flag_od_intent.md)
  intent patterns and the opioid-subtype flags
  ([`flag_heroin_present()`](https://mkiang.github.io/narcan/reference/flag_heroin_present.md)
  etc.) use anchored code patterns consistent with the death-flag
  definitions, removing latent substring over-match.

#### Internal

- Added
  [`.dispatch_era()`](https://mkiang.github.io/narcan/reference/dot-dispatch_era.md)
  as the single source of truth for ICD-9/ICD-10 era selection, shared
  by
  [`unite_records()`](https://mkiang.github.io/narcan/reference/unite_records.md)
  and the `flag_*` family.
- Expanded tests: an ICD-oracle golden test (codes -\> expected flags,
  primary- source-cited), direct unit tests for the ICD-9 munging
  helpers, era-dispatch boundary tests, and regression tests for each
  fix above.

## narcan 0.3.0

### Modernized for current R and tidyverse

This release brings a long-dormant package up to date with modern R and
tidyverse conventions and fixes several correctness issues, while
preserving the existing analysis behavior. `R CMD check` is clean (0
errors, 0 warnings).

#### Changed (behavior)

- **Minimum R is now 4.2** – the package uses the native `|>` pipe
  internally.
- **The `flag_suicide_*` family gains a `year` argument and now warns on
  pre-1999 (ICD-9) data** instead of silently returning all zeros. ICD-9
  suicide coding is not yet implemented; the warning fires only when a
  year is determinable and `< 1999`.
- **[`state_abbrev_to_fips()`](https://mkiang.github.io/narcan/reference/state_abbrev_to_fips.md)
  now zero-pads** two-digit FIPS codes (e.g. `"06"` for California, not
  `"6"`), matching
  [`add_county_fips()`](https://mkiang.github.io/narcan/reference/add_county_fips.md)
  and the NCHS convention.
- **[`unite_records()`](https://mkiang.github.io/narcan/reference/unite_records.md)
  now errors on a year outside 1979-1998 / `>= 1999`** (for example a
  two-digit `datayear` such as `93`) instead of silently returning an
  unrelated object. Pass an explicit four-digit `year`.

#### New

- The main data-consuming functions
  ([`unite_records()`](https://mkiang.github.io/narcan/reference/unite_records.md),
  [`flag_drug_deaths()`](https://mkiang.github.io/narcan/reference/flag_drug_deaths.md),
  [`flag_opioid_deaths()`](https://mkiang.github.io/narcan/reference/flag_opioid_deaths.md),
  [`flag_opioid_types()`](https://mkiang.github.io/narcan/reference/flag_opioid_types.md),
  [`flag_od_intent()`](https://mkiang.github.io/narcan/reference/flag_od_intent.md),
  [`calc_asrate_var()`](https://mkiang.github.io/narcan/reference/calc_asrate_var.md),
  [`calc_stdrate_var()`](https://mkiang.github.io/narcan/reference/calc_stdrate_var.md),
  [`add_pop_counts()`](https://mkiang.github.io/narcan/reference/add_pop_counts.md),
  [`add_std_pop()`](https://mkiang.github.io/narcan/reference/add_std_pop.md))
  now emit a plain **warning** when the first argument is not a data
  frame or is missing a required column, so a mistake surfaces by name
  rather than as a cryptic downstream error. These checks never abort.

#### Internal

- Dependency calls deprecated or defunct in current dplyr were updated
  with no change in output: `funs()` -\> `across()`, `mutate_at(vars())`
  -\> `mutate()`, `one_of()` -\> `any_of()`, and `group_by(add = TRUE)`
  -\> `group_by(.add = TRUE)`.
- Converted internal code to the native `|>` pipe, modernized the
  rate/summary helpers’ non-standard evaluation to `{{ }}` embracing,
  and replaced
  [`tidyr::gather()`](https://tidyr.tidyverse.org/reference/gather.html)
  with
  [`tidyr::pivot_longer()`](https://tidyr.tidyverse.org/reference/pivot_longer.html).
- Removed the unused `purrr` dependency.

## narcan 0.2.1

### Coding-aware race/Hispanic recode functions

The recode/label helpers previously hardcoded a single coding scheme and
applied it to every year, silently mislabeling data for years where NCHS
coding changed. They are now year-aware. Values verified against the
NCHS public-use mortality file documentation.

#### Changed (behavior)

- **`categorize_hspanicr(hspanicr_column, year = NULL)`** gains a `year`
  argument (a scalar or a vector aligned to the data column). It applies
  the 9-category scheme through 2020, returns `NA` for the reserved 2021
  field, and applies the expanded 14-category (single-race, 1997 OMB)
  scheme from 2022. Values before 1989 (not recorded) are `NA`. When
  `year` is omitted the pre-2022 9-category scheme is assumed **with a
  warning** – existing calls keep working but should pass `year` to
  label 2022+ data correctly.
- **`remap_race(icd_df, year)`** now dispatches three ways: bridged
  detailed `race` through 2020 (unchanged), `NA` for the 2021 transition
  gap (bridged race dropped, single-race recodes not yet populated), and
  the single-race Race Recode 6 (`racer5`) from 2022 mapped to a
  non-colliding code space (101-106). The internal
  `.remap_race_1992_2015` helper is renamed `.remap_race_1992_2020`.
- **[`categorize_race()`](https://mkiang.github.io/narcan/reference/categorize_race.md)**
  labels the single-race codes 101-106 (`white_only`, `black_only`,
  `american_indian_only`, `asian_only`, `nhopi_only`, `multiracial`) in
  addition to the bridged codes; the factor levels adapt to the
  scheme(s) present, so pre-2021 output is unchanged.
- Bridged (\<=2020) and single-race (2022+) race/Hispanic categories are
  **not comparable**;
  [`remap_race()`](https://mkiang.github.io/narcan/reference/remap_race.md)
  and
  [`categorize_race()`](https://mkiang.github.io/narcan/reference/categorize_race.md)
  warn when the single-race path is used, and the two must not be
  chained into a single trend.

#### New

- **[`import_mcod_fwf()`](https://mkiang.github.io/narcan/reference/import_mcod_fwf.md)
  now guarantees a canonical `year` column** (from its `year` argument),
  so downstream year dispatch works on every era including stacked
  multi-year data. 1979-1995 files retain their original `datayear`
  column as well.
- [`.extract_year()`](https://mkiang.github.io/narcan/reference/dot-extract_year.md)
  falls back to `datayear` (used by 1979-1995 files) when no `year`
  column is present.

#### Notes

- Rates for 2021+ single-race deaths need single-race population
  denominators;
  [`add_pop_counts()`](https://mkiang.github.io/narcan/reference/add_pop_counts.md)
  joins bridged-race `pop_est` only (discontinued by NCHS after Vintage
  2020). See
  [`?add_pop_counts`](https://mkiang.github.io/narcan/reference/add_pop_counts.md).
  Single-race denominators are future work.
- New `testthat` coverage for the recode functions is built from a small
  random sample of **real** public MCOD data spanning every coding era.

## narcan 0.2.0

### Byte-verified fixed-width layouts (1979-2024)

The MCOD fixed-width dictionaries were re-verified against the raw NCHS
bytes for every year (public 1979-2024 and restricted 1989-2024), not
just the NBER Stata dictionaries. narcan’s existing positions were found
to be **highly accurate**; this release makes a small set of corrections
and adds public-use support.

#### New

- **`mcod_public_fwf_dicts`** – a public-use tier dictionary, and
  **`import_mcod_fwf(file, year, tier = c("restricted", "public"))`**, a
  single exported importer for both tiers. The public importer keeps
  restricted-only / suppressed columns (sub-state geography and record
  type from 2005, certifier, tobacco, pregnancy) as all-`NA` so public
  and restricted output are column-compatible. Public effective record
  length by year: 440 (1979-2002), 488 (2003-2012), 490 (2013-2019), 817
  (2020-2024).
- **`add_coded_occupation(df, year)`** – harmonizes coded
  occupation/industry across the two non-comparable schemes (3-digit
  Census 1985-1999; 4-digit NCHS+NIOSH 2020+) into standard
  `occ_coded`/`ind_coded`/`occ_recode`/`ind_recode` columns plus
  `occ_scheme` and an `occ_available` flag, so researchers need not know
  byte positions, era, or tier. The 4-digit codes reach the public file
  in 2020 but the restricted file only in 2021 (identical from 2021).
- Coverage extended to data years **2023 and 2024** (both tiers).
- `cdc_dict` extended through the latest public-use year (**2024**);
  [`.download_mcod_fwf()`](https://mkiang.github.io/narcan/reference/dot-download_mcod_fwf.md)
  now uses the CDC HTTPS endpoint (the old `ftp://` host was
  decommissioned).
- The dictionaries are now built from reviewed source CSVs
  (`data-raw/fwf_layouts/*.csv`) by a network-free assembly script that
  writes the exported and internal copies in sync.

#### Corrections (restricted tier)

- **`hspanicr` widened from 1 byte ([@488](https://github.com/488)) to 2
  bytes ([@487-488](https://github.com/487-488)) for 2022+.** This is
  the only change that alters parsed values: reading a single byte
  truncated the 14-category Hispanic-origin/race recode to ~10
  units-digit values (e.g. Mexican `01` collided with non-Hispanic Asian
  `11`). **If you parsed 2022+ restricted data with narcan \< 0.2.0,
  re-import to recover the full recode.**
- **`racer40` ([@489-490](https://github.com/489-490)) is now declared
  for restricted 2003-2011** as a documented-but-empty field, making the
  declared record length faithful to the true 490-byte record. This adds
  an all-`NA` `racer40` column to those years’ output; no other values
  change.

#### Notes (no code change; positions were already correct)

- narcan already carried `racer40` from data year 2012 with record
  length 490 – NCHS documentation that dates it to 2018 is wrong for the
  data.
- `read_fwf()`’s newline-delimited read already handles 2005+ public
  geography suppression and the 1980 variable-length public file
  correctly.
- Some columns keep their NBER names but change meaning across an era
  boundary – see
  [`?mcod_fwf_dicts`](https://mkiang.github.io/narcan/reference/mcod_fwf_dicts.md):
  `ucr130` is all-ages in 1999-2001 (infant-only from 2002);
  `racer5`@450 is bridged Race Recode 5 through 2020 and single-race
  Race Recode 6 from 2022.

#### Internal

- Removed the stale `data-raw/making_restricted_dicts.R` (it wrote
  unrelated objects to `R/sysdata.rda` and would have clobbered the
  dictionaries if re-run).
- Added a `testthat` (edition 3) suite: dictionary integrity (types,
  monotonic positions, `max(end)` equals the expected record length),
  public/restricted column parity, a pre-2022 restricted snapshot, and
  importer round-trip / parity on synthetic fixtures.
