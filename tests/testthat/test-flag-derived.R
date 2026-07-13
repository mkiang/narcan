# Characterization (Bucket A) for three derived flags the era-level snapshots do
# not reach: flag_nonheroin, flag_nonopioid_drug_deaths, flag_opioid_contributed.
# Each is defined by a simple set relation over already-computed flags, so the
# tests lock that exact relation (not just "it ran"). ICD-10 fixture unless noted.

flagged_icd10 <- function() {
    flag_pipeline(flag_icd10_fixture(), year = 2019L, era = "icd10")$flagged
}

test_that("flag_nonheroin(): non-heroin opioid = num_opioids > 0 AND not heroin", {
    fl <- flagged_icd10()
    out <- suppressWarnings(flag_nonheroin(fl))
    expect_true("nonheroin_present" %in% names(out))
    expect_equal(
        out$nonheroin_present,
        as.numeric(fl$num_opioids > 0 & fl$heroin_present == 0)
    )
    expect_gt(sum(out$nonheroin_present), 0)
})

test_that("flag_nonopioid_drug_deaths(): drug death that is not an opioid death", {
    fl <- flagged_icd10()
    out <- suppressWarnings(flag_nonopioid_drug_deaths(fl))
    expect_true("nonop_drug_death" %in% names(out))
    expect_equal(
        out$nonop_drug_death,
        as.numeric(fl$drug_death == 1 & fl$opioid_death == 0)
    )
})

test_that("flag_opioid_contributed(): opioid in contributory but not the UCOD", {
    proc <- flag_pipeline(flag_icd10_fixture(), year = 2019L, era = "icd10")$proc
    out <- suppressWarnings(flag_opioid_contributed(proc, year = 2019L))
    expect_true("opioid_contributed" %in% names(out))
    # every flagged row: UCOD is NOT an opioid UCOD (opioid only contributes)
    flagged <- out[out$opioid_contributed == 1, ]
    expect_false(any(grepl(narcan:::.regex_opioid_icd10(ucod_codes = TRUE), flagged$ucod)))
    expect_gt(sum(out$opioid_contributed), 0)
})

test_that("flag_opioid_contributed() warns and returns NA for ICD-9 (undefined there)", {
    # ICD-9 opioid_death fires on any opioid mention, so "contributed but not the
    # underlying opioid death" is an empty set; the column is NA, not a
    # misleading always-redundant 0/1.
    proc <- flag_pipeline(flag_icd9_fixture(), year = 1993L, era = "icd9")$proc
    expect_warning(out <- flag_opioid_contributed(proc, year = 1993L),
                   "not defined for ICD-9")
    expect_true("opioid_contributed" %in% names(out))
    expect_true(all(is.na(out$opioid_contributed)))
})
