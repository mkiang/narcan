# Download population data (processed asset or primary source)

Fetches population denominators that are too large to bundle, for either
scheme. `raw = FALSE` (the default) fetches the narcan-processed
Release-asset parquet(s) (state and/or county) for the scheme and
verifies each sha256 against the shipped manifest. `raw = TRUE` instead
fetches the PRIMARY published source file(s) for the scheme – Census PEP
for `"single"`, SEER for `"bridged"` – verbatim.

## Usage

``` r
download_pop_data(
  scheme = c("single", "bridged"),
  raw = FALSE,
  refresh = FALSE,
  dest = NULL
)
```

## Arguments

- scheme:

  denominator scheme: `"single"` (default) or `"bridged"`

- raw:

  if `FALSE` (default), fetch the narcan-processed Release-asset
  parquet(s) for the scheme; if `TRUE`, fetch the primary published
  source file(s) only (not a full from-scratch reproduction of the
  backfill – see Details)

- refresh:

  re-download even if a cached copy exists

- dest:

  optional destination directory (default: the narcan cache)

## Value

the local path(s) of the fetched file(s), invisibly

## Details

`raw = TRUE` returns the recent-vintage source only and does NOT fully
reproduce the multi-vintage backfill: the single-race processed data
(2000-2024) pools 2000-2019 Census intercensal inputs and the bridged
data (1969-2024) draws on more than one SEER extract, none of which the
manifest lists. For a complete from-scratch rebuild use the `data-raw/`
builders. `raw = TRUE` emits a one-time message saying as much, so an
incomplete pull never silently looks complete.

Files cache under `tools::R_user_dir("narcan", "cache")`. Only bulk
flat-files are used (never the Census Data API); requests carry a
generic `narcan/<version>` User-Agent and no personal identifiers.

## Examples

``` r
if (FALSE) { # \dontrun{
# processed parquet(s) for the scheme (analysis-ready)
download_pop_data(scheme = "single")
# primary published source file(s) (recent vintage only; see Details)
download_pop_data(scheme = "single", raw = TRUE)
} # }
```
