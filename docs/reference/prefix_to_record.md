# Add the prefix to appropriate ICD-9 record columns

For record columns, codes between 800-999 can be either nature of injury
(N) or external cause of injury (E) codes. To determine the correct
code, there is a corresponding nature of injury flag column where 0
indicates an E code and 1 indicates an N code. This takes the
record/flag pair of columns and prefixes the record column as
appropriate.

## Usage

``` r
prefix_to_record(record_col, rnifla_col)
```

## Arguments

- record_col:

  The record column from an ICD-9 dataframe

- rnifla_col:

  The corresponding nature of injury flag column

## Value

vector

## Examples

``` r
record_col <- c(7500, 8000, 8001, 9999, 10000)
rnifla_col <- c(0, 1, 0, 1, 0)
prefix_to_record(record_col, rnifla_col)
#> [1] "7500"  "N8000" "E8001" "N9999" "10000"
```
