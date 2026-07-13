# Replace state abbreviations with their corresponding FIPS code

Only the 50 US states and the District of Columbia are recognized;
territory abbreviations (e.g. \`"PR"\`, \`"GU"\`, \`"VI"\`) return
\`NA\`, as narcan is US-only.

## Usage

``` r
state_abbrev_to_fips(column)
```

## Arguments

- column:

  a vector of strings with state abbreviations

## Value

a new vector with state FIPS (\`NA\` for unrecognized abbreviations)

## Examples

``` r
state_abbrev_to_fips(c("CA", "NY", "TX"))
#> [1] "06" "36" "48"
```
