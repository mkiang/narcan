# Remap the raw NCHS detail-age field to age in completed years

The NCHS "detail age" field (\`age\`) is unit-coded, and its encoding
changed at data year 2003: 1979-2002 use a 3-digit code, 2003 onward a
4-digit code. In both eras a leading digit gives the unit (years,
months, weeks, days, hours, minutes, or "not stated"). This dispatches
on the data year and returns age in completed years in a new
\`age_years\` column: sub-year ages (months/weeks/days/ hours/minutes)
collapse to \`0\`, and not-stated ages become \`NA\`.

## Usage

``` r
remap_age(df, year = NULL)
```

## Arguments

- df:

  an MCOD data frame for a single data year, with the raw \`age\` column

- year:

  data year; if \`NULL\`, extracted from the data frame

## Value

\`df\` with an added numeric \`age_years\` column

## Details

The era boundary is 2003 (the death-certificate revision), NOT the
ICD-9/ ICD-10 boundary at 1999. \`age_years\` is single completed years,
so it is not directly comparable to the pre-binned \`ager27\` recode
consumed by \[convert_ager27()\] / \[categorize_age_5()\]; to bin it
into 5-year groups use, e.g., \`pmin(floor(age_years / 5) \* 5, 85)\`.

## Examples

``` r
df <- data.frame(year = 2019, age = c(1037, 2006, 1999, 9999))
remap_age(df)$age_years          # 37 (years), 0 (months), NA, NA
#> [1] 37  0 NA NA
```
