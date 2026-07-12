# Add the external cause flag (E) to appropriate ICD-9 UCOD codes

All UCOD ICD-9 codes between 800 and 999 are external cause of injury
(E) codes. Because this operates on the padded 4-character code (e.g.
"8001" for 800.1, as produced by
[`pad_3char_codes()`](https://mkiang.github.io/narcan/reference/pad_3char_codes.md),
which
` `[`clean_icd9_data()`](https://mkiang.github.io/narcan/reference/clean_icd9_data.md)
already runs before this), the numeric guard checks 8000-9999, the
padded-code equivalent of the 800-999 range. We append the E to them to
make regexing across UCOD and record columns consistent.

## Usage

``` r
prefix_e_to_ucod(icd9_ucod)
```

## Arguments

- icd9_ucod:

  The ucod column from an ICD-9 dataframe

## Value

vector

## Examples

``` r
prefix_e_to_ucod(c(7951, 8001, 9992, 6000, 4000))
#> [1] "7951"  "E8001" "E9992" "6000"  "4000" 
```
