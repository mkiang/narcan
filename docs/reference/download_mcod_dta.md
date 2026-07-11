# Download the multiple cause of death data as a DTA file

NBER hosts publicly available multiple cause of death data in several
formats (see source). This function downloads the specified year to the
specified folder in the DTA (Stata) format.

## Usage

``` r
download_mcod_dta(year, download_dir = "./raw_data")
```

## Source

http://www.nber.org/data/vital-statistics-mortality-data-multiple-cause-of-death.html

## Arguments

- year:

  year to download (as integer)

- download_dir:

  file path to save downloaded data

## Value

none

## Examples

``` r
if (FALSE) { # \dontrun{
download_mcod_dta(2019, download_dir = tempdir())
} # }
```
