# `narcan` [![Build Status](https://travis-ci.com/mkiang/narcan.svg?token=3q3DFBRyXorCzLQs97qL&branch=master)](https://travis-ci.com/mkiang/narcan)

An R package for working with [multiple cause of death micro-data](https://wonder.cdc.gov/mcd.html). 

## Introduction
Certain types of deaths, including drug overdoses or opioid-related deaths, are defined by an [ICD code](http://www.who.int/classifications/icd/en/) in both the underlying cause field and one of the twenty possible contributory cause fields. Therefore, in order to tabulate these deaths, researches cannot use [compressed mortality files (CMF)](https://www.cdc.gov/nchs/data_access/cmf.htm) (which contain only underlying cause of death), but rather must use [multiple cause of death (MCOD)](https://wonder.cdc.gov/mcd.html) data.

This simple package aims to make common operations---such as downloading, munging, and cleaning---on MCOD data easier. 

Additionally, this package includes data necessary for calculating rates. Specifically, standard populations and annual US population counts from 1979 to 2015.

## Usage
TODO

## Sources
### Multiple Cause of Death
Multiple cause of death data (in multiple formats), documentation, dictionaries, and other information are stored on the [National Bureau of Economic Research (NBER) website](http://www.nber.org/data/vital-statistics-mortality-data-multiple-cause-of-death.html).

The data itself come from the [National Center for Health Statistics](https://www.cdc.gov/nchs/nvss/mortality_methods.htm) and are subject to [their data use agreement](https://www.cdc.gov/nchs/data_access/restrictions.htm). A GUI interface for these data are provided by [CDC Wonder](https://wonder.cdc.gov/)

### Standard Populations
Standard populations are stored on the [Surveillance, Epidemiology, and End Results (SEER)](https://seer.cancer.gov/stdpopulations/) section of the National Cancer Institute website.

### Population Estimates
THe annual US population estimates come from the United States Census Bureau's [Population Estimates Program (PEP)](https://www.census.gov/programs-surveys/popest.html).

## Papers using `narcan`
- **Put `opioid_disparities` paper here when submitted.**
- **Put `opioid_intent` paper here when submitted.**
- **Potentially `opioid_age`.**

## Authors
[Mathew Kiang](https://mathewkiang.com) ([`mkiang`](https://github.com/mkiang)) and [Monica Alexander](http://monicaalexander.com/) ([`MJAlexander`](https://github.com/mjalexander))

## Technical Notes
### Hidden Functions
This package contains several functions that are **not** user-facing. This functions begin with a period (`.`) and can be accessed using the triple colon syntax (`:::`). 

For example, all functions used to download and create the standard populations and population estimates datasets are hidden from the user. Accessing the data directly is preferable (e.g., `narcan::std_pops`); however, for completeness, we document hidden functions here. Note that each "chunk" of population data requires different munging and is thus kept in a different function. Functions themselves contain further documentation.

- `narcan:::.download_standard_pops()`
- `narcan:::.download_1979_pop_data()`
- `narcan:::.download_1980s_pop_data()`
- `narcan:::.download_1990s_pop_data()`
- `narcan:::.download_2000s_pop_data()`
- `narcan:::.download_2010s_pop_data()`
- `narcan:::.download_all_pop_data()`