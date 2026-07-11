# Download the multiple cause of death data as a CSV file

NBER hosts publicly available multiple cause of death data in several
formats (see source). This function downloads the specified year to the
specified folder in the CSV format.

## Usage

``` r
download_mcod_csv(year, download_dir = "./raw_data", territories = FALSE)
```

## Source

http://www.nber.org/data/vital-statistics-mortality-data-multiple-cause-of-death.html

## Arguments

- year:

  year to download (as integer)

- download_dir:

  file path to save download data

- territories:

  download US territories

## Value

none

## Examples

``` r
if (FALSE) { # \dontrun{
download_mcod_csv(2019, download_dir = tempdir())
} # }
```
