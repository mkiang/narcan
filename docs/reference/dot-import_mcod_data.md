# Shared engine for importing restricted/public MCOD fixed-width data

Selects the byte-verified dictionary for `year_x` and `tier` (by bare
name, resolving to the internal copy in `R/sysdata.rda`), builds the
[`readr::fwf_positions()`](https://readr.tidyverse.org/reference/read_fwf.html)
and the `col_types` string from the SAME rows in stored order (so they
stay aligned, including the intentional nested/overlapping geography
fields), reads the file, appends any suppressed columns as typed
all-`NA`, and reorders to the canonical restricted column order for
column parity across tiers.

## Usage

``` r
.import_mcod_data(
  file,
  year_x,
  tier = c("restricted", "public"),
  dict = NULL,
  restricted_dict = NULL
)
```

## Arguments

- file:

  path to the raw fixed-width file

- year_x:

  year of MCOD data

- tier:

  `"restricted"` or `"public"`

- dict:

  optional dictionary to use instead of the packaged one (for tests)

- restricted_dict:

  optional restricted dictionary defining the canonical column order
  (for tests); defaults to the packaged `mcod_fwf_dicts`

## Value

a tibble
