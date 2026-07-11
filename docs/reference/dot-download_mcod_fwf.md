# Download the multiple cause of death data as an ASCII file from the CDC

The CDC hosts publicly available multiple cause of death data as a
fixed- width text file. This function downloads that file as a zip. Note
that the CDC server can be slow–downloading from NBER via the
download_mcod_dta() or download_mcod_csv() functions is strongly
suggested. Coverage in `cdc_dict` runs through the most recent
public-use year (currently 2024).

## Usage

``` r
.download_mcod_fwf(year, download_dir = "./raw_data")
```

## Source

https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/DVS/mortality/

## Arguments

- year:

  year to download (as integer)

- download_dir:

  file path to save downloaded data

## Value

none
