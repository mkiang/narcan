# Trim ICD-9 record columns that include the nature of injury flag

For some years, the ICD-9 record columns are 5 character codes with the
last character representing the nature of injury (N) flag. Just trim off
these columns and use the appropriate rnifla\_ column for the N flag.

## Usage

``` r
trim_5char_record(record_col)
```

## Arguments

- record_col:

  The record column from an ICD-9 dataframe

## Value

vector

## Examples

``` r
trim_5char_record(c("400 1", "40000", "400", "400 "))
#> [1] "400 " "4000" "400"  "400 "
```
