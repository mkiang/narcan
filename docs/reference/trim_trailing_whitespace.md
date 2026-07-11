# Trim trailing whitespace on 3-char ICD-9 codes

Some of the ICD-9 codes only contain 3 characters (i.e., they do not
contain subcodes) but have a space at the end. This function just takes
the record column and strips out the trailing space.

## Usage

``` r
trim_trailing_whitespace(icd9_record)
```

## Arguments

- icd9_record:

  One of the record columns from an ICD-9 dataframe

## Value

vector

## Examples

``` r
trim_trailing_whitespace(c("400 ", "402", "4032"))
#> [1] "400"  "402"  "4032"
```
