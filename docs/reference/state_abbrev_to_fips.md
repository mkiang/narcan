# Replace state abbreviations with their corresponding FIPS code

Replace state abbreviations with their corresponding FIPS code

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
