# Trends in unspecified drug overdose deaths

Many drug-overdose death certificates never name the specific drug
involved. That gap biases drug-specific trends – an apparent rise in one
opioid can reflect improved toxicology and reporting specificity rather
than a real increase in that drug. In ICD-10 data (1999 onward), the
opioid deaths with no specific type are coded T40.6, “other and
unspecified narcotics”, which narcan flags as `other_op_present`. This
vignette measures the T40.6 share of opioid deaths by year, end to end,
on small illustrative records; no restricted NCHS data are used and no
chunk downloads anything.

[`library`](https://rdrr.io/r/base/library.html)`(`[`narcan`](https://github.com/mkiang/narcan)`)`

## Illustrative records

The frame below is **synthetic and illustrative**. Each row is one
death, coded in the ICD-10 convention – `ucod` is the underlying-cause
code and `f_records_all` is the space-joined multiple-cause T-code
string. Opioid deaths carry a poisoning `ucod` (X42, accidental
poisoning by narcotics) plus one T40.x opioid code: heroin (T40.1),
synthetic opioids such as fentanyl (T40.4), or the “other and
unspecified” residual (T40.6). Two cocaine deaths per year (T40.5) are
included so the opioid filter has something to remove. Counts are chosen
so the T40.6 share falls as more deaths get a specific opioid type over
time.

`recipe`` ``<-`` ``tibble``::`[`tribble`](https://tibble.tidyverse.org/reference/tribble.html)`(`` `` ``~``year``, ``~``ucod``, ``~``f_records_all``, ``~``n``,`` `` ``1999L``, ``"X42"``, ``"T401"``, ``4L``, ``# heroin`` `` ``1999L``, ``"X42"``, ``"T404"``, ``2L``, ``# synthetic (e.g. fentanyl)`` `` ``1999L``, ``"X42"``, ``"T406"``, ``4L``, ``# other/unspecified opioid`` `` ``1999L``, ``"X42"``, ``"T405"``, ``2L``, ``# cocaine (non-opioid drug death)`` `` ``2005L``, ``"X42"``, ``"T401"``, ``5L``,`` `` ``2005L``, ``"X42"``, ``"T404"``, ``3L``,`` `` ``2005L``, ``"X42"``, ``"T406"``, ``4L``,`` `` ``2005L``, ``"X42"``, ``"T405"``, ``2L``,`` `` ``2012L``, ``"X42"``, ``"T401"``, ``6L``,`` `` ``2012L``, ``"X42"``, ``"T404"``, ``6L``,`` `` ``2012L``, ``"X42"``, ``"T406"``, ``3L``,`` `` ``2012L``, ``"X42"``, ``"T405"``, ``2L``,`` `` ``2019L``, ``"X42"``, ``"T401"``, ``8L``,`` `` ``2019L``, ``"X42"``, ``"T404"``, ``9L``,`` `` ``2019L``, ``"X42"``, ``"T406"``, ``3L``,`` `` ``2019L``, ``"X42"``, ``"T405"``, ``2L`` ``)`` ``deaths`` ``<-`` ``recipe``[`[`rep`](https://rdrr.io/r/base/rep.html)`(`[`seq_len`](https://rdrr.io/r/base/seq.html)`(`[`nrow`](https://rdrr.io/r/base/nrow.html)`(``recipe``)``)``, ``recipe``$``n``)``,`` `` `[`c`](https://rdrr.io/r/base/c.html)`(``"year"``, ``"ucod"``, ``"f_records_all"``)``]`` `[`rownames`](https://rdrr.io/r/base/colnames.html)`(``deaths``)`` ``<-`` ``NULL`` `[`nrow`](https://rdrr.io/r/base/nrow.html)`(``deaths``)`` ``#> [1] 65`

## Walk the flags, one step at a time

Each flag keys on `ucod` plus `f_records_all`, and the ICD era is read
from `year`, so run the pipeline one year at a time. Here is the 2012
slice through each step.

[`flag_drug_deaths()`](https://mkiang.github.io/narcan/reference/flag_drug_deaths.md)
adds `drug_death` – for ICD-10 it is 1 when a qualifying poisoning
`ucod` pairs with a drug T-code. All four 2012 record types qualify.

`d12`` ``<-`` ``deaths``[``deaths``$``year`` ``==`` ``2012``, ``]`` ``s1`` ``<-`` `[`flag_drug_deaths`](https://mkiang.github.io/narcan/reference/flag_drug_deaths.md)`(``d12``, year ``=`` ``2012``)`` `[`head`](https://rdrr.io/r/utils/head.html)`(``s1``)`` ``#> ``# A tibble: 6 × 4`` ``#> year ucod f_records_all drug_death`` ``#> ``<int>`` ``<chr>`` ``<chr>`` ``<dbl>`` ``#> ``1`` ``2``012 X42 T401 1`` ``#> ``2`` ``2``012 X42 T401 1`` ``#> ``3`` ``2``012 X42 T401 1`` ``#> ``4`` ``2``012 X42 T401 1`` ``#> ``5`` ``2``012 X42 T401 1`` ``#> ``6`` ``2``012 X42 T401 1`

[`flag_opioid_deaths()`](https://mkiang.github.io/narcan/reference/flag_opioid_deaths.md)
adds `opioid_death`, which additionally requires a T40.0-.4 or T40.6
opioid code. The three opioid rows stay 1; the cocaine death (T40.5)
drops to 0.

`s2`` ``<-`` `[`flag_opioid_deaths`](https://mkiang.github.io/narcan/reference/flag_opioid_deaths.md)`(``s1``, year ``=`` ``2012``)`` `[`unique`](https://rdrr.io/r/base/unique.html)`(`[`subset`](https://rdrr.io/r/base/subset.html)`(``s2``, ``f_records_all`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``"T401"``, ``"T406"``, ``"T405"``)``)``)`` ``# heroin, other/unspecified, cocaine`` ``#> ``# A tibble: 3 × 5`` ``#> year ucod f_records_all drug_death opioid_death`` ``#> ``<int>`` ``<chr>`` ``<chr>`` ``<dbl>`` ``<dbl>`` ``#> ``1`` ``2``012 X42 T401 1 1`` ``#> ``2`` ``2``012 X42 T406 1 1`` ``#> ``3`` ``2``012 X42 T405 1 0`

[`flag_opioid_types()`](https://mkiang.github.io/narcan/reference/flag_opioid_types.md)
adds the six specific-type columns, the ICD-9-era residual
`unspecified_op_present`, and `num_opioids`. The T40.6 deaths land in
`other_op_present`; `unspecified_op_present` stays 0 (see the closing
note).

`s3`` ``<-`` `[`flag_opioid_types`](https://mkiang.github.io/narcan/reference/flag_opioid_types.md)`(``s2``, year ``=`` ``2012``)`` ``type_cols`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``"ucod"``, ``"f_records_all"``, ``"opioid_death"``, ``"heroin_present"``,`` `` ``"other_synth_present"``, ``"other_op_present"``,`` `` ``"unspecified_op_present"``, ``"num_opioids"``)`` `[`as.data.frame`](https://rdrr.io/r/base/as.data.frame.html)`(`[`unique`](https://rdrr.io/r/base/unique.html)`(``s3``[``s3``$``opioid_death`` ``==`` ``1``, ``type_cols``]``)``)`` ``#> ucod f_records_all opioid_death heroin_present other_synth_present`` ``#> 1 X42 T401 1 1 0`` ``#> 2 X42 T404 1 0 1`` ``#> 3 X42 T406 1 0 0`` ``#> other_op_present unspecified_op_present num_opioids`` ``#> 1 0 0 1`` ``#> 2 0 0 1`` ``#> 3 1 0 1`

## Unspecified (T40.6) share by year

Apply the same three steps to every year, keep the opioid deaths, and
take the mean of `other_op_present` per year – that mean is the T40.6
share.

`flagged`` ``<-`` ``dplyr``::`[`bind_rows`](https://dplyr.tidyverse.org/reference/bind_rows.html)`(`[`lapply`](https://rdrr.io/r/base/lapply.html)`(`[`split`](https://rdrr.io/r/base/split.html)`(``deaths``, ``deaths``$``year``)``, ``function``(``d``)`` ``{`` `` ``y`` ``<-`` ``d``$``year``[``1``]`` `` ``d`` ``|>`` `` `[`flag_drug_deaths`](https://mkiang.github.io/narcan/reference/flag_drug_deaths.md)`(``year ``=`` ``y``)`` ``|>`` `` `[`flag_opioid_deaths`](https://mkiang.github.io/narcan/reference/flag_opioid_deaths.md)`(``year ``=`` ``y``)`` ``|>`` `` `[`flag_opioid_types`](https://mkiang.github.io/narcan/reference/flag_opioid_types.md)`(``year ``=`` ``y``)`` ``}``)``)`` `` ``unspec`` ``<-`` ``flagged`` ``|>`` `` ``dplyr``::`[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``opioid_death`` ``==`` ``1``)`` ``|>`` `` ``dplyr``::`[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``year``)`` ``|>`` `` ``dplyr``::`[`summarize`](https://dplyr.tidyverse.org/reference/summarise.html)`(`` `` opioid_deaths ``=`` ``dplyr``::`[`n`](https://dplyr.tidyverse.org/reference/context.html)`(``)``,`` `` t406_unspecified ``=`` `[`sum`](https://rdrr.io/r/base/sum.html)`(``other_op_present``)``,`` `` t406_share ``=`` `[`round`](https://rdrr.io/r/base/Round.html)`(`[`mean`](https://rdrr.io/r/base/mean.html)`(``other_op_present``)``, ``3``)``,`` `` .groups ``=`` ``"drop"`` `` ``)`` ``unspec`` ``#> ``# A tibble: 4 × 4`` ``#> year opioid_deaths t406_unspecified t406_share`` ``#> ``<int>`` ``<int>`` ``<dbl>`` ``<dbl>`` ``#> ``1`` ``1``999 10 4 0.4 `` ``#> ``2`` ``2``005 12 4 0.333`` ``#> ``3`` ``2``012 15 3 0.2 `` ``#> ``4`` ``2``019 20 3 0.15`

The T40.6 share falls from 0.40 in 1999 to 0.15 in 2019 – built into
these illustrative counts, but the identical computation on real MCOD
records recovers whatever trend the data actually hold.

[`library`](https://rdrr.io/r/base/library.html)`(`[`ggplot2`](https://ggplot2.tidyverse.org)`)`` `` `[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``unspec``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``x ``=`` ``year``, y ``=`` ``t406_share``)``)`` ``+`` `` `[`geom_line`](https://ggplot2.tidyverse.org/reference/geom_path.html)`(``)`` ``+`` `` `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``)`` ``+`` `` `[`labs`](https://ggplot2.tidyverse.org/reference/labs.html)`(`` `` x ``=`` ``"Year"``,`` `` y ``=`` ``"T40.6 share of opioid deaths"``,`` `` title ``=`` ``"Unspecified-opioid-type (T40.6) share by year"`` `` ``)`

![Line-and-point chart of the T40.6 (other and unspecified opioid) share
of opioid deaths by year. The share falls from about 0.40 in 1999 to
about 0.15 in
2019.](unspecified-drug-deaths_files/figure-html/plot-1.png)

T40.6 (other/unspecified opioid) share of opioid deaths by year,
computed from the illustrative records above.

## Caveats

T40.6 is the standard ICD-10 proxy for an unspecified opioid, but the
label is “other **and** unspecified narcotics”, so a T40.6 death is one
where the specific opioid was not distinguished, not strictly one that
is missing. This is the opioid *type*-unspecified share, not the broader
problem of drug deaths with no specific drug coded at all, which spans
non-opioid drugs too. narcan also carries `unspecified_op_present`, the
ICD-9-era residual keyed to the generic opiate code 965.0; it is 0 by
construction for years \>= 1999 because ICD-10 folds the unspecified
opioids into T40.6, which is exactly why the modern measure reads
`other_op_present` instead. Some analysts redistribute T40.6 deaths
across the known types before computing drug-specific rates; narcan
gives you the raw flags so you can measure the unspecified share first
and decide how to adjust for it yourself.

The unspecified share also varies markedly **by jurisdiction**, not only
over time – some states (Pennsylvania is a persistent example) code a
far higher fraction as unspecified than others (Buchanich et al. 2018;
Ruhm 2018), and ISW7 notes the opioid purity of T40.6 itself varies by
jurisdiction (it can occasionally capture non-opioid narcotics). A
reassuring national decline can hide states where specificity stays
poor, so check the share sub-nationally before trusting drug-specific
rates there.

## See also

- [`vignette("classifying-overdose-deaths")`](https://mkiang.github.io/narcan/articles/classifying-overdose-deaths.md)
  – the full ISW7 flag pipeline behind the three steps walked through
  here.
- [`vignette("getting-started")`](https://mkiang.github.io/narcan/articles/getting-started.md)
  – the full raw-data-to-rate pipeline and where this vignette fits.
