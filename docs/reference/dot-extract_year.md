# Helper function that extracts year from a dataframe and raises error if more than one.

MCOD files name the year column \`year\` from data year 1996 onward but
\`datayear\` for 1979-1995. This checks \`year\` first, then falls back
to \`datayear\`, and errors if neither column is present.

## Usage

``` r
.extract_year(df)
```

## Arguments

- df:

  dataframe to extract year from

## Value

year as integer (four-digit)

## Details

The 1979-1995 files store \`datayear\` as a two-digit value (e.g. 85 for
1985). A two-digit value is normalized to its four-digit year (+1900),
since every two-digit \`datayear\` is a 19xx year. Without this,
downstream year dispatch (\`.dispatch_era()\`, \`remap_race()\`,
\`categorize_hspanicr()\`) sees a value like 85 that matches no coding
era and either errors or silently mislabels.
