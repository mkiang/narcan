# Package index

## Overview

- [`narcan`](https://mkiang.github.io/narcan/reference/narcan-package.md)
  [`narcan-package`](https://mkiang.github.io/narcan/reference/narcan-package.md)
  : narcan: tools for US multiple cause of death (MCOD) data

## Import & download

Read raw fixed-width MCOD files and download source data.

- [`import_mcod_fwf()`](https://mkiang.github.io/narcan/reference/import_mcod_fwf.md)
  : Import MCOD fixed-width data (restricted or public tier)
- [`download_mcod_csv()`](https://mkiang.github.io/narcan/reference/download_mcod_csv.md)
  : Download the multiple cause of death data as a CSV file
- [`download_mcod_dta()`](https://mkiang.github.io/narcan/reference/download_mcod_dta.md)
  : Download the multiple cause of death data as a DTA file
- [`download_natality_ascii()`](https://mkiang.github.io/narcan/reference/download_natality_ascii.md)
  : Download NCHS Natality (Live Births) Data from the CDC FTP (ASCII)
- [`download_pop_data()`](https://mkiang.github.io/narcan/reference/download_pop_data.md)
  : Download population data (processed asset or primary source)
- [`mkdir_p()`](https://mkiang.github.io/narcan/reference/mkdir_p.md) :
  Wrapper to make a directory (and subdirectories) if necessary

## Clean & reshape records

Prepare imported records for flagging.

- [`unite_records()`](https://mkiang.github.io/narcan/reference/unite_records.md)
  : Unite the 20 record columns from MCOD dataframe into a single column
- [`clean_icd9_data()`](https://mkiang.github.io/narcan/reference/clean_icd9_data.md)
  : A wrapper function to perform basic cleaning of ICD-9 dataframes
- [`zap_dta_data()`](https://mkiang.github.io/narcan/reference/zap_dta_data.md)
  : Clear Stata metadata from MCOD dta files
- [`subset_residents()`](https://mkiang.github.io/narcan/reference/subset_residents.md)
  : Subset to US residents
- [`prefix_to_record()`](https://mkiang.github.io/narcan/reference/prefix_to_record.md)
  : Add the prefix to appropriate ICD-9 record columns
- [`prefix_e_to_ucod()`](https://mkiang.github.io/narcan/reference/prefix_e_to_ucod.md)
  : Add the external cause flag (E) to appropriate ICD-9 UCOD codes
- [`pad_3char_codes()`](https://mkiang.github.io/narcan/reference/pad_3char_codes.md)
  : Pad ICD-9 codes that do not have a sub-code (i.e., 3-character
  codes)
- [`trim_5char_record()`](https://mkiang.github.io/narcan/reference/trim_5char_record.md)
  : Trim ICD-9 record columns that include the nature of injury flag
- [`trim_trailing_whitespace()`](https://mkiang.github.io/narcan/reference/trim_trailing_whitespace.md)
  : Trim trailing whitespace on 3-char ICD-9 codes
- [`rename_ni_flag()`](https://mkiang.github.io/narcan/reference/rename_ni_flag.md)
  : Rename nature of injury columns for consistency

## Flag & label deaths (ISW7)

Classify drug, opioid, intent, suicide, and maternal deaths.

- [`flag_all_deaths()`](https://mkiang.github.io/narcan/reference/flag_all_deaths.md)
  : Run the canonical MCOD flagging pipeline
- [`flag_drug_deaths()`](https://mkiang.github.io/narcan/reference/flag_drug_deaths.md)
  : Flag drug deaths according to ISW7 rules
- [`flag_heroin_present()`](https://mkiang.github.io/narcan/reference/flag_heroin_present.md)
  : Creates a new column called heroin_present if opioid death involved
  heroin
- [`flag_maternal_deaths()`](https://mkiang.github.io/narcan/reference/flag_maternal_deaths.md)
  : Creates a new column called maternal_death with 1 if maternal death
- [`flag_maternal_deaths_late()`](https://mkiang.github.io/narcan/reference/flag_maternal_deaths_late.md)
  : Creates a new column called maternal_death with 1 if maternal death
  (late)
- [`flag_methadone_present()`](https://mkiang.github.io/narcan/reference/flag_methadone_present.md)
  : Creates a column \`methadone_present\` if opioid death involved
  methadone
- [`flag_nonheroin()`](https://mkiang.github.io/narcan/reference/flag_nonheroin.md)
  : Flag all opioid deaths that were not from heroin
- [`flag_nonopioid_drug_deaths()`](https://mkiang.github.io/narcan/reference/flag_nonopioid_drug_deaths.md)
  : Flag non-opioid drug deaths according to ISW7 rules
- [`flag_od_intent()`](https://mkiang.github.io/narcan/reference/flag_od_intent.md)
  : Flag overdose deaths by their UCOD intent code
- [`flag_opioid_contributed()`](https://mkiang.github.io/narcan/reference/flag_opioid_contributed.md)
  : Flag non-opioid deaths that involved opioids
- [`flag_opioid_deaths()`](https://mkiang.github.io/narcan/reference/flag_opioid_deaths.md)
  : Flag opioid deaths according to ISW7 rules
- [`flag_opioid_types()`](https://mkiang.github.io/narcan/reference/flag_opioid_types.md)
  : Take a processed MCOD dataframe and create indicators for opioid
  types
- [`flag_opium_present()`](https://mkiang.github.io/narcan/reference/flag_opium_present.md)
  : Creates a column called \`opium_present\` if opioid death involved
  opium
- [`flag_other_natural_present()`](https://mkiang.github.io/narcan/reference/flag_other_natural_present.md)
  : Creates a column \`other_natural_present\` if opioid death involved
  opium
- [`flag_other_op_present()`](https://mkiang.github.io/narcan/reference/flag_other_op_present.md)
  : Creates a column \`other_op_present\` for deaths with other
  unspecified opioid
- [`flag_other_synth_present()`](https://mkiang.github.io/narcan/reference/flag_other_synth_present.md)
  : Creates a column called \`other_synth_present\`
- [`flag_suicide_deaths()`](https://mkiang.github.io/narcan/reference/flag_suicide_deaths.md)
  : Flag suicide deaths (no accidental poisoning)
- [`flag_suicide_fall()`](https://mkiang.github.io/narcan/reference/flag_suicide_fall.md)
  : Flag suicide by fall
- [`flag_suicide_firearm()`](https://mkiang.github.io/narcan/reference/flag_suicide_firearm.md)
  : Flag suicide by firearm
- [`flag_suicide_other()`](https://mkiang.github.io/narcan/reference/flag_suicide_other.md)
  : Flag suicide by other (not poison, fall, firearm, suffocation)
- [`flag_suicide_poison()`](https://mkiang.github.io/narcan/reference/flag_suicide_poison.md)
  : Flag suicide by poison
- [`flag_suicide_suffocation()`](https://mkiang.github.io/narcan/reference/flag_suicide_suffocation.md)
  : Flag suicide by suffocation
- [`flag_suicide_types()`](https://mkiang.github.io/narcan/reference/flag_suicide_types.md)
  : Flag suicide five types: firearm, poisoning, fall, suffocation, or
  other
- [`label_od_intent()`](https://mkiang.github.io/narcan/reference/label_od_intent.md)
  : Label intent from underlying cause column for overdose drugs
- [`label_suicide_type()`](https://mkiang.github.io/narcan/reference/label_suicide_type.md)
  : Create a new column with labels for suicide type

## Recode demographics & geography

Year-aware race, sex, Hispanic origin, age, occupation, and FIPS
recodes.

- [`remap_race()`](https://mkiang.github.io/narcan/reference/remap_race.md)
  : Remaps the race column to a standardized code across data years
- [`categorize_race()`](https://mkiang.github.io/narcan/reference/categorize_race.md)
  : Create a categorical race column from a standardized race column
- [`categorize_sex()`](https://mkiang.github.io/narcan/reference/categorize_sex.md)
  : Categorize the NCHS sex field across coding eras
- [`categorize_female()`](https://mkiang.github.io/narcan/reference/categorize_female.md)
  : Flag female deaths across coding eras
- [`categorize_hspanicr()`](https://mkiang.github.io/narcan/reference/categorize_hspanicr.md)
  : Create a categorical Hispanic origin/race column from the hspanicr
  column
- [`add_hspanicr_column()`](https://mkiang.github.io/narcan/reference/add_hspanicr_column.md)
  : Add an NA hspanicr column if one doesn't exist
- [`categorize_hispanic_origin()`](https://mkiang.github.io/narcan/reference/categorize_hispanic_origin.md)
  : Collapse hspanicr to the binary Hispanic-origin axis (for population
  joins)
- [`add_hispanic_origin()`](https://mkiang.github.io/narcan/reference/add_hispanic_origin.md)
  : Add a binary Hispanic-origin column from hspanicr
- [`remap_age()`](https://mkiang.github.io/narcan/reference/remap_age.md)
  : Remap the raw NCHS detail-age field to age in completed years
- [`categorize_age_5()`](https://mkiang.github.io/narcan/reference/categorize_age_5.md)
  : Create a categorical age column from a converted ager27 column
- [`categorize_age_5u1()`](https://mkiang.github.io/narcan/reference/categorize_age_5u1.md)
  : Create a categorical age column from a converted ager27 column
- [`convert_ager27()`](https://mkiang.github.io/narcan/reference/convert_ager27.md)
  : Converts the age27 variable in MCOD data to 5-year age groups
- [`convert_ager27u1()`](https://mkiang.github.io/narcan/reference/convert_ager27u1.md)
  : Converts the age27 variable in MCOD data to under-1, 1-4, then
  5-year groups
- [`add_county_fips()`](https://mkiang.github.io/narcan/reference/add_county_fips.md)
  : Make a new county_fips column that is consistent across years
- [`state_abbrev_to_fips()`](https://mkiang.github.io/narcan/reference/state_abbrev_to_fips.md)
  : Replace state abbreviations with their corresponding FIPS code
- [`add_coded_occupation()`](https://mkiang.github.io/narcan/reference/add_coded_occupation.md)
  : Add harmonized coded occupation and industry columns

## Population & rates

Population denominators and (standardized) mortality rates.

- [`get_pop_state()`](https://mkiang.github.io/narcan/reference/get_pop_state.md)
  : Retrieve state-level population denominators
- [`get_pop_county()`](https://mkiang.github.io/narcan/reference/get_pop_county.md)
  : Retrieve county-level population denominators
- [`pop_sources()`](https://mkiang.github.io/narcan/reference/pop_sources.md)
  : Print the bundled population-data provenance manifest
- [`add_pop_counts()`](https://mkiang.github.io/narcan/reference/add_pop_counts.md)
  : Join population denominators to a death frame
- [`add_std_pop()`](https://mkiang.github.io/narcan/reference/add_std_pop.md)
  : Given a dataframe with age, returns a standard population
- [`calc_asrate_var()`](https://mkiang.github.io/narcan/reference/calc_asrate_var.md)
  : Calculate age-specific rates and variance
- [`calc_stdrate_var()`](https://mkiang.github.io/narcan/reference/calc_stdrate_var.md)
  : Calculate age-standardized rates and variance
- [`summarize_binary_columns()`](https://mkiang.github.io/narcan/reference/summarize_binary_columns.md)
  : Summarizes all flagged (e.g., 0/1) MCOD columns

## Datasets

Bundled reference tables and crosswalks.

- [`appalachia_fips`](https://mkiang.github.io/narcan/reference/appalachia_fips.md)
  : Dataframe of Appalachian counties with name and FIPS codes
- [`cdc_dict`](https://mkiang.github.io/narcan/reference/cdc_dict.md) :
  A dictionary of year:URL key:value pairs for the CDC FTP MCOD files
- [`ihme_fips`](https://mkiang.github.io/narcan/reference/ihme_fips.md)
  : Mapping original FIPS codes to temporally stable FIPS codes from
  IHME
- [`live_births`](https://mkiang.github.io/narcan/reference/live_births.md)
  : Dataframe of live births in the US from 2003-2016 by race/ethnicity
  and age.
- [`mcod_fwf_dicts`](https://mkiang.github.io/narcan/reference/mcod_fwf_dicts.md)
  : Fixed-width column dictionary for RESTRICTED-use MCOD files
- [`mcod_public_fwf_dicts`](https://mkiang.github.io/narcan/reference/mcod_public_fwf_dicts.md)
  : Fixed-width column dictionary for PUBLIC-use MCOD files
- [`pop_bridged`](https://mkiang.github.io/narcan/reference/pop_bridged.md)
  : Bridged-race population estimates, national, 1969-2024
- [`pop_est`](https://mkiang.github.io/narcan/reference/pop_est.md) :
  Dataframe of annual population counts by age and race, 1979-2020
- [`pop_singlerace`](https://mkiang.github.io/narcan/reference/pop_singlerace.md)
  : Single-race population estimates, national, 2020-2024
- [`pop_singlerace_full`](https://mkiang.github.io/narcan/reference/pop_singlerace_full.md)
  : Single-race population estimates, national, 2000-2024 (backfill)
- [`pop_singlerace_state`](https://mkiang.github.io/narcan/reference/pop_singlerace_state.md)
  : Single-race population estimates, state, 2020-2024
- [`st_fips_map`](https://mkiang.github.io/narcan/reference/st_fips_map.md)
  : Mapping of US state name to abbreviation to FIPS and NCHS code
- [`std_pops`](https://mkiang.github.io/narcan/reference/std_pops.md) :
  Dataframe of common standard populations from SEER website.
