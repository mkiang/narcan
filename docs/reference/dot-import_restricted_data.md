# Wrapper for importing restricted MCOD data

Restricted MCOD data contains geographical location (for years after
2004), that the public-use files do not contain. Further, restricted
files come as plaintext, fixed-width files. This helper function simply
imports these text files with known dictionaries.

## Usage

``` r
.import_restricted_data(file, year_x)
```

## Arguments

- file:

  path to restricted MCOD plaintext file

- year_x:

  year of MCOD data

## Value

dataframe

## See also

\[import_mcod_fwf()\] for the public (and exported) entry point.
