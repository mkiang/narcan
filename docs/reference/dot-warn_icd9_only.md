# Warn that an ICD-10-only flag was handed pre-1999 (ICD-9) data

Emits a single warning when \`year\` is determinable and \< 1999, so
ICD-9 years do not silently return all zeros. Does nothing when \`year\`
is NULL/NA. ICD-9 cause detection is not implemented (a future work
item).

## Usage

``` r
.warn_icd9_only(year, fn)
```

## Arguments

- year:

  a single year (or NULL)

- fn:

  name of the calling function (for the message)

## Value

invisibly NULL
