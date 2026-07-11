# Downloads the NBER Stata dct file and returns a dictionary with column data

The NBER has Stata dictionary files for each of the MCOD public use
datasets or Natality public use datasets. This function downloads the
dictionary file and converts it to a dataframe with column name, column
start position, column end position, and column time (in readr::col()
format).

## Usage

``` r
.dct_to_fwf_df(year, natality = FALSE)
```

## Source

http://www.nber.org/data/vital-statistics-mortality-data-multiple-cause-of-death.html

http://www.nber.org/data/vital-statistics-natality-data.html

## Arguments

- year:

  year of the dictionary you want to convert

- natality:

  set to TRUE if you want to download natality dictionaries

## Value

dataframe
