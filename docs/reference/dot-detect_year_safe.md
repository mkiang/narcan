# Best-effort year detection that never errors (unlike .extract_year)

Returns the explicit \`year\` if given, else the first value of a
\`year\` or \`datayear\` column if present, else NULL. Used by the ICD-9
guards so a year-less data frame preserves current behavior rather than
erroring.

## Usage

``` r
.detect_year_safe(df, year = NULL)
```

## Arguments

- df:

  dataframe

- year:

  explicit year (or NULL to detect)

## Value

a single year, or NULL if undeterminable
