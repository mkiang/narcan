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
