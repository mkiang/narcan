# Summarizes all flagged (e.g., 0/1) MCOD columns

To use this, you must remove all non-grouping, non-binary variables.

## Usage

``` r
summarize_binary_columns(df, ...)
```

## Arguments

- df:

  a dataframe with binary flag columns to indicate type of death, plus
  the required grouping columns \`year\`, \`age\`, and \`age_cat\`

- ...:

  grouping variables (in addition to year, age, and age_cat)

## Value

dataframe

## Details

Rows are grouped by \`year\`, \`age\`, and \`age_cat\` (plus any bare
variables passed in \`...\`); all three columns are required. The
function stops early with a clear message if any is missing, rather than
failing with a cryptic dplyr error deep inside \`group_by()\`. Create
\`age_cat\` with \[categorize_age_5()\]. Every remaining non-grouping
column is summed as a 0/1 flag.

## Examples

``` r
df <- data.frame(
    year = c(2019, 2019),
    age = c(25, 25),
    age_cat = c("20-24", "20-24"),
    opioid_death = c(1, 0),
    drug_death = c(1, 1)
)
summarize_binary_columns(df)
#> # A tibble: 1 × 6
#> # Groups:   year, age [1]
#>    year   age age_cat deaths opioid_death drug_death
#>   <dbl> <dbl> <chr>    <int>        <dbl>      <dbl>
#> 1  2019    25 20-24        2            1          2
```
