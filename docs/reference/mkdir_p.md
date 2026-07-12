# Wrapper to make a directory (and subdirectories) if necessary

Mimics \`mkdir -p\` by making a directory and all subdirectories and
suppressing error messages if folder already exists.

## Usage

``` r
mkdir_p(path)
```

## Arguments

- path:

  Location of folder to be made

## Value

None

## Examples

``` r
d <- file.path(tempdir(), "narcan_example_dir")
mkdir_p(d)
unlink(d, recursive = TRUE)
```
