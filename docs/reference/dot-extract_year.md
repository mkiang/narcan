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

year as integer
