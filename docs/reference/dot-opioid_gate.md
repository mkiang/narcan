# Build the opioid-death gate for the opioid-type flags

Shared by \`flag_opioid_types()\` and its subtype flags. When
\`opioid_deaths_only\` is \`TRUE\` (the default), returns the defused
expression \`opioid_death == 1\` for injection (with \`!!\`) into a
\`case_when()\`, so the gate is evaluated in the data mask and is
therefore grouped/\`rowwise()\`-safe; it errors clearly first if the
\`opioid_death\` column is absent (it is required in that mode). When
\`FALSE\`, returns a scalar \`TRUE\`, so the type fires wherever its
code appears and \`opioid_death\` is not referenced at all.

## Usage

``` r
.opioid_gate(df, opioid_deaths_only, fn = "")
```

## Arguments

- df:

  the processed data frame

- opioid_deaths_only:

  logical scalar

- fn:

  name of the calling function (for the error message)

## Value

an injectable expression (\`opioid_death == 1\`) or scalar \`TRUE\`
