# Golden test: narcan's ISW7 flag logic vs the frozen, primary-source-cited ICD
# oracle (fixtures/icd_oracle.csv; authoritative copy in the private review
# wrapper). Because narcan uses the COMBINED UCOD-AND-T rule for ICD-10, bare
# record/UCOD rows are PAIRED with a qualifying counterpart before asserting.
# ICD-9 uses a curated set of the 5-char stored forms narcan matches (the oracle
# also lists ICD-9-CM 5th-digit subcodes and 4-char category codes that do not
# occur in NCHS mortality fixed-width files).

oracle <- readr::read_csv(
    testthat::test_path("fixtures", "icd_oracle.csv"),
    comment = "#", show_col_types = FALSE
)
# expect_* columns carry "na" on informational (era-boundary) rows, so read as
# character; coerce to numeric for the code/record/ucod rows the loops assert on.
oracle$expect_drug_death <- suppressWarnings(as.numeric(oracle$expect_drug_death))
oracle$expect_opioid_death <- suppressWarnings(as.numeric(oracle$expect_opioid_death))

flag_one <- function(ucod, records, year) {
    df <- data.frame(year = year, ucod = ucod, f_records_all = records,
                     stringsAsFactors = FALSE)
    df |>
        flag_drug_deaths(year = year, keep_cols = TRUE) |>
        flag_opioid_deaths(year = year, keep_cols = TRUE)
}
do_flags <- function(ucod, records, year) {
    o <- flag_one(ucod, records, year)
    c(o$drug_death, o$opioid_death)
}

test_that("ICD-10 record T-codes classify under the combined rule (paired with a drug UCOD)", {
    rec <- oracle[oracle$era == "icd10" & oracle$position == "record" &
                      !is.na(oracle$stored), ]
    expect_gt(nrow(rec), 0)
    for (i in seq_len(nrow(rec))) {
        out <- flag_one("X42", rec$stored[i], 2019L)
        expect_equal(out$drug_death, rec$expect_drug_death[i],
                     info = paste("drug_death for", rec$code[i]))
        expect_equal(out$opioid_death, rec$expect_opioid_death[i],
                     info = paste("opioid_death for", rec$code[i]))
    }
})

test_that("ICD-10 UCOD codes gate classification (paired with a non-opioid drug T-code)", {
    uc <- oracle[oracle$era == "icd10" & oracle$position == "ucod" &
                     !is.na(oracle$stored) & !grepl("[+(]", oracle$code), ]
    expect_gt(nrow(uc), 0)
    for (i in seq_len(nrow(uc))) {
        out <- flag_one(uc$stored[i], "T509", 2019L)
        expect_equal(out$drug_death, uc$expect_drug_death[i],
                     info = paste("drug_death for", uc$code[i]))
        expect_equal(out$opioid_death, uc$expect_opioid_death[i],
                     info = paste("opioid_death for", uc$code[i]))
    }
})

test_that("ICD-10 combined-rule paired cases (primary regressions incl. T40.5/T40.6)", {
    expect_equal(do_flags("X42", "T401", 2019L), c(1, 1))   # heroin -> drug+opioid
    expect_equal(do_flags("X42", "", 2019L), c(0, 0))       # drug UCOD, no T-code
    expect_equal(do_flags("V892", "T401", 2019L), c(0, 0))  # opioid T, non-drug UCOD
    expect_equal(do_flags("X44", "T509", 2019L), c(1, 0))   # unspecified drug
    expect_equal(do_flags("X42", "T405", 2019L), c(1, 0))   # T40.5 cocaine excluded
    expect_equal(do_flags("X60", "T402", 2019L), c(1, 1))   # suicide opioid
    expect_equal(do_flags("X42", "T406", 2019L), c(1, 1))   # T40.6 included (freeze)
})

test_that("ICD-9 flags on curated 5-char stored codes (incl. #5 E859 boundary)", {
    expect_equal(do_flags("E8500", "", 1990L), c(1, 1))     # heroin
    expect_equal(do_flags("E8501", "", 1990L), c(1, 1))     # methadone
    expect_equal(do_flags("E8502", "", 1990L), c(1, 1))     # other opioid
    expect_equal(do_flags("E8543", "", 1990L), c(1, 0))     # psychotropic, non-opioid
    expect_equal(do_flags("E8588", "", 1990L), c(1, 0))     # E858 edge, drug
    expect_equal(do_flags("E8590", "", 1990L), c(0, 0))     # E859 -> NOT drug (#5)
    expect_equal(do_flags("", "N9650", 1990L), c(1, 1))     # opioid nature (record)
    expect_equal(do_flags("", "N9670", 1990L), c(1, 0))     # sedative nature, drug
    expect_equal(do_flags("", "N9800", 1990L), c(0, 0))     # alcohol nature, not drug
})
