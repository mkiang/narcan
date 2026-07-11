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
mkdir_p('./test_directory')
```
