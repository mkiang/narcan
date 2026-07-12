# Flag female deaths across coding eras

A thin wrapper on \[categorize_sex()\] returning \`1\` for female, \`0\`
for male, and \`NA\` for an unmapped/missing code.

## Usage

``` r
categorize_female(sex_column, year = NULL)
```

## Arguments

- sex_column:

  a vector of raw NCHS sex codes

- year:

  data year: a scalar, a vector aligned to \`sex_column\`, or \`NULL\`
  to infer the era from the column type

## Value

an integer vector of \`1\` (female) / \`0\` (male) / \`NA\`

## Examples

``` r
categorize_female(c(1, 2), year = 2000)      # 0 1
#> [1] 0 1
categorize_female(c("M", "F"), year = 2019)  # 0 1
#> [1] 0 1
```
