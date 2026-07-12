# Converts the age27 variable in MCOD data to under-1, 1-4, then 5-year groups

Converts the age27 variable in MCOD data to under-1, 1-4, then 5-year
groups

## Usage

``` r
convert_ager27u1(icd_df, remove_age27 = TRUE)
```

## Arguments

- icd_df:

  an MCOD dataframe with age27 as a column

- remove_age27:

  once a new column is created, remove the old age27

## Value

dataframe

## Details

Expects \`ager27\` in its documented domain (codes 1-27, where 27 is
"age not stated" and maps to \`NA\`). A non-\`NA\` value outside 1-27
triggers a warning, since it would otherwise fall through the recode and
become \`NA\`.

NCHS Age Recode 27: codes 1-2 are deaths under 1 year (\`Under 1
month\`, \`1 month - 11 months\`) and map to \`age = 0\` (the \`\<1\`
bin); codes 3-6 are \`1 year\`, \`2 years\`, \`3 years\`, \`4 years\`
(collectively \`1-4 years\`) and map to \`age = 1\`. Codes 7-26 use the
same 5-year mapping as \[convert_ager27()\].

## Examples

``` r
df <- data.frame(ager27 = c(1, 3, 10, 27))
convert_ager27u1(df)
#>   age
#> 1   0
#> 2   1
#> 3  20
#> 4  NA
```
