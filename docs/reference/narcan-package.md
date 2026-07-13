# narcan: tools for US multiple cause of death (MCOD) data

narcan turns raw NCHS Multiple Cause of Death micro-data into drug- and
opioid-overdose death counts and age-standardized rates, using the
Injury Surveillance Workgroup (ISW7) ICD-9/ICD-10 definitions.

The canonical pipeline has four steps, each with a vignette:

1.  **Import** the raw fixed-width file
    ([`import_mcod_fwf`](https://mkiang.github.io/narcan/reference/import_mcod_fwf.md))
    and collapse its multiple-cause fields
    ([`unite_records`](https://mkiang.github.io/narcan/reference/unite_records.md)).

2.  **Flag** drug/opioid deaths
    ([`flag_drug_deaths`](https://mkiang.github.io/narcan/reference/flag_drug_deaths.md),
    [`flag_opioid_deaths`](https://mkiang.github.io/narcan/reference/flag_opioid_deaths.md),
    [`flag_opioid_types`](https://mkiang.github.io/narcan/reference/flag_opioid_types.md));
    see
    [`vignette("classifying-overdose-deaths")`](https://mkiang.github.io/narcan/articles/classifying-overdose-deaths.md).

3.  **Denominators**: join population counts with
    [`add_pop_counts`](https://mkiang.github.io/narcan/reference/add_pop_counts.md);
    see
    [`vignette("population-denominators")`](https://mkiang.github.io/narcan/articles/population-denominators.md).

4.  **Rates**: age-standardize with
    [`add_std_pop`](https://mkiang.github.io/narcan/reference/add_std_pop.md)
    and
    [`calc_stdrate_var`](https://mkiang.github.io/narcan/reference/calc_stdrate_var.md);
    see
    [`vignette("age-standardized-rates")`](https://mkiang.github.io/narcan/articles/age-standardized-rates.md).

Stratify by Hispanic origin
([`vignette("hispanic-origin")`](https://mkiang.github.io/narcan/articles/hispanic-origin.md))
or harmonize geography
([`vignette("geography-fips")`](https://mkiang.github.io/narcan/articles/geography-fips.md))
as needed. New users should start with
[`vignette("getting-started")`](https://mkiang.github.io/narcan/articles/getting-started.md).

## See also

Useful links:

- <https://github.com/mkiang/narcan>

- <https://mkiang.github.io/narcan/>

- Report bugs at <https://github.com/mkiang/narcan/issues>

## Author

**Maintainer**: Mathew Kiang <mathew.kiang@gmail.com>

Authors:

- Monica Alexander <monicaalexander@berkeley.edu>
