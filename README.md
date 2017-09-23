# `narcan` [![Build Status](https://travis-ci.com/mkiang/narcan.svg?token=3q3DFBRyXorCzLQs97qL&branch=master)](https://travis-ci.com/mkiang/narcan)

An R package for working with [multiple cause of death micro-data](https://wonder.cdc.gov/mcd.html). 

## Warning
**This package is in the alpha stage.** We cannot emphasize this enough. Nothing is guaranteed to work. [Submit an issue](https://github.com/mkiang/narcan/issues) if you find a bug. 

## Introduction
Certain types of deaths, including drug overdoses or opioid-related deaths, are defined by an [ICD code](http://www.who.int/classifications/icd/en/) in both the underlying cause field and one of the twenty possible contributory cause fields. Therefore, in order to tabulate these deaths, researches cannot use [compressed mortality files (CMF)](https://www.cdc.gov/nchs/data_access/cmf.htm) (which contain only underlying cause of death), but rather must use [multiple cause of death (MCOD)](https://wonder.cdc.gov/mcd.html) data.

This simple package aims to make common operations --- such as downloading, munging, and cleaning --- on (inherently messy) MCOD data easier. 

Additionally, this package includes data necessary for calculating rates. Specifically, standard populations and annual US population counts from 1979 to 2015. Note that if you are only using 1990 to current, the [NVSS Bridged Race](https://www.cdc.gov/nchs/nvss/bridged_race.htm) files are preferred.

This package is largely the result of our internal code getting reused for multiple papers --- therefore, the scope and usefulness of the code is likely limited. We're releasing it publicly just in the hopes that other researchers will learn from our mistakes.

## Installation
Use `devtools::install_github("mkiang/narcan")` to install the current version. We have no plans of submitting this package to CRAN. 

## Usage
### Downloading MCOD Data

**TODO**

### Accessing Population Data
Standard populations are held in the `std_pops` dataframe while annual population estimates (by race, sex, and age) from 1979 to 2015 are held in the `pop_est` dataframe.

```
library(narcan)
population_estimates <- narcan::pop_est
standard_populations <- narcan::std_pops
```

### More information
There are also several wiki examples on how to use `narcan`

- [ICD-9 / dta](https://github.com/mkiang/narcan/wiki/ICD-9-download-to-clean-example-(dta)): Download, select, filter, and clean the ICD-9 data in `dta` format.
- **TODO** Make one for ICD 10 csv
- **TODO** Make one using two years with two separate race variables
- **TODO** Make one showing `rnifla_` and `rniflag`

## Irregularlities in MCOD Data
It is worth noting that there are several important irregularities in the data. This package addresses some while others are simply the way the data are.

- From 1979 to 1998, data are coded using the ICD-9 classification.
- From 1999 to 2015, data are coded using the ICD-10 classification.
- For years using the ICD-9 classification, the `rnifla_` column indicates a nature of injury flag for the corresponding `record_` column. A `1` indicates an `N` code (nature of injury) while a `0` represents all other codes (e.g., `E` for external causes or `V` coeds).
- Some years call the nature of injury flag column `rnifla_` while others call it `rniflag_`. 
- Early year `ascii` and `csv` files from NBER contain encoding errors. We suggest downloading files as `dta` for ICD-9 years and `csv` files for ICD-10 years.
- Hispanic origin is not recorded until 1989.
- Race codes changed across years.
- Some years code sex as `M`/`F` and others as `1`/`0` or `1`/`2` .
- In the restricted files, the documentation suggests state variables are coded as FIPS; however, they are actually coded as state abbreviations. 

## Sources
### Multiple Cause of Death
Multiple cause of death data (in multiple formats), documentation, dictionaries, and other information are stored on the [National Bureau of Economic Research (NBER) website](http://www.nber.org/data/vital-statistics-mortality-data-multiple-cause-of-death.html).

The data itself come from the [National Center for Health Statistics](https://www.cdc.gov/nchs/nvss/mortality_methods.htm) and are subject to [their data use agreement](https://www.cdc.gov/nchs/data_access/restrictions.htm). A GUI interface for these data are provided by [CDC Wonder](https://wonder.cdc.gov/)

### Standard Populations
Standard populations are stored on the [Surveillance, Epidemiology, and End Results (SEER)](https://seer.cancer.gov/stdpopulations/) section of the National Cancer Institute website.

### Population Estimates
THe annual US population estimates come from the United States Census Bureau's [Population Estimates Program (PEP)](https://www.census.gov/programs-surveys/popest.html).

## Papers using `narcan`
- **TODO** Put `opioid_disparities` paper here when submitted.
- **TODO** Put `opioid_intent` paper here when submitted.
- **TODO** Put `opioid_spatial` paper here when submitted.
- **TODO** Potentially `opioid_age`.

## Authors
[Mathew Kiang](https://mathewkiang.com) ([`mkiang`](https://github.com/mkiang)) and [Monica Alexander](http://monicaalexander.com/) ([`MJAlexander`](https://github.com/mjalexander))

## Technical Notes
### Hidden Functions
This package contains several functions that are **not** user-facing. This functions begin with a period (`.`) and can be accessed using the triple colon syntax (`:::`). 

### Hidden Data

**TODO** 

