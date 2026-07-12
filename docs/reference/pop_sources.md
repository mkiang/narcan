# Print the bundled population-data provenance manifest

Shows every population dataset narcan can provide – scheme, grain,
vintage, source URL, coverage, and delivery – from the shipped
`inst/extdata/pop_manifest.csv`. Use it to check which vintage a bundled
dataset carries before mixing it with a freshly downloaded one.

## Usage

``` r
pop_sources()
```

## Value

the manifest, invisibly, as a data frame

## Examples

``` r
pop_sources()
#>                     dataset  scheme    grain               vintage year_min
#>              pop_singlerace  single national                 V2024     2020
#>        pop_singlerace_state  single    state                 V2024     2020
#>         pop_singlerace_full  single national int2000/int2010/V2024     2000
#>                 pop_bridged bridged national        seer_1969_2024     1969
#>  pop_singlerace_county_full  single   county int2000/int2010/V2024     2000
#>   pop_singlerace_state_full  single    state int2000/int2010/V2024     2000
#>           pop_bridged_state bridged    state        seer_1969_2024     1969
#>          pop_bridged_county bridged   county        seer_1969_2024     1969
#>  year_max   n_rows
#>      2024     2160
#>      2024   110160
#>      2024    10800
#>      2024    12348
#>      2024 33946560
#>      2024   550800
#>      2024   619920
#>      2024 26329797
#>                                                                                                               note
#>                                                                    bundled .rda; derived by summing the state file
#>                                                                                        bundled .rda (frozen 0.5.0)
#>  bundled .rda (2000-2024 backfill); pre-2020 from intercensal state PEP (see data-raw/build_pop_singlerace_full.R)
#>                                                      bundled .rda (SEER-uniform bridged; era-ragged pre/post-1990)
#>                  Release-asset parquet (~31.6MB); 2000-2024 backfill; supersedes the v0.5.0 2020-2024 county asset
#>                                                                 Release-asset parquet (~1.1MB); 2000-2024 backfill
#>                                                                                     Release-asset parquet (~1.4MB)
#>                                                                                    Release-asset parquet (~45.9MB)
```
