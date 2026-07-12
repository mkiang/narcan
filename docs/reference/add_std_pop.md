# Given a dataframe with age, returns a standard population

Attaches a standard-population column (\`pop_std\`) and its unit weights
(\`unit_w\`, summing to 1 across the standard's age groups), matched on
\`age\`. The default \`"s204"\` is the US 2000 standard in 18 five-year
age groups (0, 5, ..., 85), which matches narcan's binned \`age\`.

## Usage

``` r
add_std_pop(df, std_cat = "s204", by_vars = "age")
```

## Arguments

- df:

  dataframe with age column (in 5-year bins)

- std_cat:

  standard population to use (default: US 2000 standard pop); must share
  \`df\`'s age grouping (see Details)

- by_vars:

  variables to merge on

## Value

dataframe

## Details

The \`std_cat\` must use the SAME age grouping as \`df\`. The 18-group
five-year standards match narcan's 5-year bins; a single-year standard
(e.g. \`"s202"\`, \`"s205"\`) joined to 5-year-binned ages matches only
the bin-start years and silently misweights every stratum. When the
joined weights do not sum to ~1, this warns.

## Examples

``` r
df <- data.frame(age = seq(0, 85, 5))
add_std_pop(df)
#>    age  pop_std     unit_w
#> 1    0 18986520 0.06913399
#> 2    5 19919840 0.07253241
#> 3   10 20056779 0.07303103
#> 4   15 19819518 0.07216712
#> 5   20 18257225 0.06647847
#> 6   25 17722067 0.06452985
#> 7   30 19511370 0.07104508
#> 8   35 22179956 0.08076198
#> 9   40 22479229 0.08185169
#> 10  45 19805793 0.07211714
#> 11  50 17224359 0.06271759
#> 12  55 13307234 0.04845449
#> 13  60 10654272 0.03879449
#> 14  65  9409940 0.03426361
#> 15  70  8725574 0.03177169
#> 16  75  7414559 0.02699800
#> 17  80  4900234 0.01784280
#> 18  85  4259173 0.01550856
```
