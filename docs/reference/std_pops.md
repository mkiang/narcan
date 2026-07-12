# Dataframe of common standard populations from SEER website.

A data set containing a variety of common standard populations
including: 2000 US standard million, 2000 US standard population, 1960
world standard million, WHO standard million in 18 age groups, 19 age
groups, single-year age to 85, and single-year age to 100 bins. Created
by using the download_standard_pops() function.

## Usage

``` r
std_pops
```

## Format

A data frame with 1015 rows and 5 columns

- age_cat:

  factor, age group

- standard_cat:

  factor, description of standard population. Five raw SEER standards
  (`s13`-`s17`) are currently unlabeled (`NA`); reference them by their
  `standard` code.

- pop_std:

  count, population in that age group for that standard

- standard:

  code, character code for that standard population

- age:

  starting age of that age group

## Source

<https://seer.cancer.gov/stdpopulations/stdpop.18ages.txt>
