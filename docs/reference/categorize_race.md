# Create a categorical race column from a standardized race column

Labels the standardized race codes produced by remap_race(). The
bridged-race scheme (2020 and earlier) uses codes 0-7 and 99; the
single-race scheme (2022+) uses the non-colliding codes 101-106. The
factor levels adapt to whichever scheme(s) are present, so pre-2021 data
is labeled exactly as before.

## Usage

``` r
categorize_race(race_column)
```

## Arguments

- race_column:

  race column created from remap_race()

## Value

an ordered factor

## Details

The single-race categories are labeled with an \`\_only\` suffix
(matching the NCHS "(only)" wording) and are NOT comparable to the
bridged categories – do not combine the two schemes into a single trend.

## Examples

``` r
categorize_race(c(0, 1, 1, 1, 0:7, 99))
#>  [1] total           white           white           white          
#>  [5] total           white           black           american_indian
#>  [9] chinese         japanese        hawaiian        filipino       
#> [13] other          
#> 9 Levels: total < white < black < american_indian < chinese < ... < other
categorize_race(c(101, 102, 104, 106))
#> Warning: single-race codes (101-106) are not comparable to the bridged race scheme (2020 and earlier); do not combine the two into a single trend.
#> [1] white_only  black_only  asian_only  multiracial
#> 6 Levels: white_only < black_only < american_indian_only < ... < multiracial
```
