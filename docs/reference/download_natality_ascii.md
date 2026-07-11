# Download NCHS Natality (Live Births) Data from the CDC FTP (ASCII)

Fair warning: These files are very large when uncompressed. They range
between 3 and 5 GB uncompressed with a compression ratio of around 90
Also, it appears the CDC rate limits downloads so I do not export this
function. To use it, you'll need to use the triple colon:
\`narcan:::download_natality_ascii()\`.

## Usage

``` r
download_natality_ascii(year, download_dir = "./raw_data", return_path = FALSE)
```

## Source

https://www.cdc.gov/nchs/data_access/vitalstatsonline.htm

## Arguments

- year:

  year to download (as integer)

- download_dir:

  file path to save downloaded data

- return_path:

  return the path of the file that was downloaded

## Value

none

## Details

Further, the unzip() function in R will not unzip files that are larger
than 4GB so this needs to be unzipped using a system call or external
program.
