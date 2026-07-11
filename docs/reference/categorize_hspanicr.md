# Create a categorical Hispanic origin/race column from the hspanicr column

The hspanicr (Hispanic Origin/Race Recode) column was not recorded
before 1989 and its coding changed across data years: a 9-category
scheme through 2020, reserved/not populated in 2021, and an expanded
14-category (single-race, 1997 OMB) scheme from 2022. This labels each
value using the scheme that applies to its data year, so functions like
tidyr::complete() will expand rows that have no observations.

## Usage

``` r
categorize_hspanicr(hspanicr_column, year = NULL)
```

## Arguments

- hspanicr_column:

  hspanicr column from an MCOD dataframe

- year:

  data year(s); a single value or a vector aligned to `hspanicr_column`.
  If `NULL`, the pre-2022 9-category scheme is assumed (with a warning)
  for backward compatibility.

## Value

an ordered factor

## Details

The pre-2022 and 2022+ schemes are not comparable – the old "Central or
South American" splits into Dominican, Central American, and South
American, and non-Hispanics gain single-race detail – so a factor
spanning the 2021 boundary must not be treated as a single ordered
scale.

## Examples

``` r
categorize_hspanicr(c(1:5, NA, 9, 8, 4), year = 2019)
#> [1] mexican               puerto_rican          cuban                
#> [4] central_south_america other_hispanic        <NA>                 
#> [7] hispanic_unknown      nonhispanic_other     central_south_america
#> 9 Levels: mexican < puerto_rican < cuban < ... < hispanic_unknown
categorize_hspanicr(c(1, 4, 10, 13, 14), year = 2023)
#> [1] mexican           dominican         nonhispanic_aian  nonhispanic_multi
#> [5] hispanic_unknown 
#> 14 Levels: mexican < puerto_rican < cuban < dominican < ... < hispanic_unknown
```
