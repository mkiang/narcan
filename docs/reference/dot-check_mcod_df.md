# Warn (never abort) when a user-facing entry point gets a malformed frame

Minimal, non-breaking input check shared by the main data-consuming
functions. Emits one warning if \`df\` is not a data frame, and one
warning naming any \`need\` columns that are absent, so the caller gets
a named signal instead of a downstream "object not found" (from a
data-masked \`grepl()\`) or join error. It never aborts – processing
continues and any genuine error still surfaces where it would have
before.

## Usage

``` r
.check_mcod_df(df, need = character(), fn = "")
```

## Arguments

- df:

  the object passed as the function's data argument

- need:

  character vector of column names the caller requires and does not
  create itself

- fn:

  name of the calling function (for the message)

## Value

invisibly NULL
