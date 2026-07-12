# Dispatch the ICD coding era for a data year

Single source of truth for era selection across the flag\_\* family and
unite_records(). Returns "icd9" (1979-1998) or "icd10" (\>= 1999) and
errors on a 2-digit \`datayear\` (e.g. 93) or any 4-digit year before
1979, so an out-of-range year can never silently fall through into the
wrong branch.

## Usage

``` r
.dispatch_era(year)
```

## Arguments

- year:

  a single 4-digit data year

## Value

"icd9" or "icd10"
