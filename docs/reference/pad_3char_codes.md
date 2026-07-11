# Pad ICD-9 codes that do not have a sub-code (i.e., 3-character codes)

Some of the ICD-9 codes only contain 3 characters (i.e., they do not
contain subcodes). This function just takes the UCOD column and converts
all of these 3 character codes into 4 by padding a zero at the end.

## Usage

``` r
pad_3char_codes(icd9_ucod)
```

## Arguments

- icd9_ucod:

  The ucod column from an ICD-9 dataframe

## Value

vector

## Examples

``` r
pad_3char_codes(c("400", "4043", "304", "5062"))
#> [1] "4000" "4043" "3040" "5062"
```
