## A tiny synthetic restricted dictionary + matching fixed-width records, used to
## exercise the importer engine without any real (DUA) data. Overlapping fields
## (st nested in cty) mirror the real geography nesting.
mini_restricted_dict <- function(year = 2050L) {
    tibble::tibble(
        name  = c("cty",   "st",    "sex", "age",  "ucod"),
        type  = c("c",     "c",     "c",   "n",    "c"),
        start = c(1L,      1L,      6L,    7L,     9L),
        end   = c(5L,      2L,      6L,    8L,     12L),
        year  = year
    )
}

## public variant: geography suppressed (NA positions), same names for parity
mini_public_dict <- function(year = 2050L) {
    d <- mini_restricted_dict(year)
    d$suppressed <- d$name %in% c("cty", "st")
    d$start[d$suppressed] <- NA_integer_
    d$end[d$suppressed] <- NA_integer_
    d
}

## fixed-width lines matching mini_restricted_dict: cty(1-5) st(1-2 nested) sex(6)
## age(7-8) ucod(9-12)
mini_fixture_lines <- function() {
    c(
        "06075M07C509",
        "36061F88X44 "
    )
}

write_fixture <- function() {
    f <- withr::local_tempfile(fileext = ".txt", .local_envir = parent.frame())
    writeLines(mini_fixture_lines(), f, sep = "\n")
    f
}

## Real public-MCOD flag fixtures (built by verify_fwf/scripts/71_build_flag_fixtures.R;
## reviewed and landed by MK). ICD-9 rows are raw (pre-clean_icd9_data); ICD-10 rows
## carry ucod + record_1..20. See fixtures/ for the .rds; coverage documented in the
## builder's manifest.
flag_icd9_fixture  <- function() readRDS(test_path("fixtures", "flag_icd9_sample.rds"))
flag_icd10_fixture <- function() readRDS(test_path("fixtures", "flag_icd10_sample.rds"))

## Run narcan's documented flag pipeline on a raw fixture and return the pieces:
##   proc    -- after clean_icd9_data (ICD-9 only) + unite_records
##   flagged -- proc |> flag_drug_deaths |> flag_opioid_deaths |> flag_opioid_types
##              |> flag_od_intent  (the full numerator + type + intent frame)
## Warnings are muffled (they are not what these characterization tests lock; the
## flag OUTPUT is). Maternal/suicide are separate branches -- tests call those
## directly on $proc.
flag_pipeline <- function(raw, year, era) {
    proc0 <- if (era == "icd9") clean_icd9_data(raw) else raw
    proc <- suppressWarnings(unite_records(proc0, year = year))
    flagged <- proc |>
        (\(x) suppressWarnings(flag_drug_deaths(x, year = year)))() |>
        (\(x) suppressWarnings(flag_opioid_deaths(x, year = year)))() |>
        (\(x) suppressWarnings(flag_opioid_types(x, year = year)))() |>
        (\(x) suppressWarnings(flag_od_intent(x, year = year)))()
    list(proc = proc, flagged = flagged)
}

## Named integer vector of flag sums over a frame, in a fixed column order, for
## compact and reviewable snapshot characterization.
flag_sums <- function(df) {
    cols <- c("drug_death", "opioid_death", "opium_present", "heroin_present",
              "other_natural_present", "methadone_present", "other_synth_present",
              "other_op_present", "unspecified_op_present", "num_opioids",
              "multi_opioids", "unintended_intent", "suicide_intent",
              "homicide_intent", "undetermined_intent")
    cols <- cols[cols %in% names(df)]
    vapply(cols, function(c) as.integer(sum(df[[c]], na.rm = TRUE)), integer(1))
}

## A small REAL aggregated input for the rate/pop family. Denominators come from
## the bundled narcan::pop_est (real bridged-race estimates); the numerator is a
## deterministic small count (pure arithmetic -- not MCOD micro-data, so inventing
## the count is fine per the fixture convention). One year/sex/race across all
## 18 five-year age bins, so add_pop_counts()/add_std_pop() joins resolve fully.
## year 2015 is used deliberately (pop_est also holds an artifact year 420).
rate_input <- function(year = 2015L, sex = "male", race = "white") {
    keys <- narcan::pop_est[
        narcan::pop_est$year == year &
            narcan::pop_est$sex == sex &
            narcan::pop_est$race == race,
        c("year", "age", "sex", "race")
    ]
    keys <- keys[order(keys$age), ]
    keys$deaths <- rep(c(5, 10, 20, 40, 80), length.out = nrow(keys))
    tibble::as_tibble(keys)
}
