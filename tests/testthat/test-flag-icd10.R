# Characterization (Bucket A) for the ICD-10 (>=1999) flag pipeline, on the real
# 2019 public fixture. The colSums snapshot locks the aggregate behavior of the
# whole drug/opioid/type/intent family in one reviewable place; a refactor that
# changes any flag's logic changes the snapshot. Targeted properties lock the
# ISW7 rules the plan's review called out (opioid subset of drug; the UCOD-AND-
# T-code rule and its edges).

test_that("ICD-10 flag pipeline colSums are stable", {
    r <- flag_pipeline(flag_icd10_fixture(), year = 2019L, era = "icd10")
    expect_snapshot(flag_sums(r$flagged))
})

test_that("ICD-10 opioid deaths are a subset of drug deaths", {
    r <- flag_pipeline(flag_icd10_fixture(), year = 2019L, era = "icd10")
    f <- r$flagged
    expect_true(all(f$opioid_death[f$opioid_death == 1] <= f$drug_death[f$opioid_death == 1]))
    expect_true(all(f$drug_death[f$opioid_death == 1] == 1))
})

test_that("ICD-10 opioid death requires a drug UCOD AND an opioid T-code (edges resolve to 0)", {
    r <- flag_pipeline(flag_icd10_fixture(), year = 2019L, era = "icd10")
    f <- r$flagged
    ucod_op  <- grepl(narcan:::.regex_opioid_icd10(ucod_codes = TRUE), f$ucod)
    tcode_op <- grepl(narcan:::.regex_opioid_icd10(t_codes = TRUE), f$f_records_all)
    # both edge sets must be non-empty or the checks below are vacuous
    expect_gt(sum(ucod_op & !tcode_op), 0)
    expect_gt(sum(!ucod_op & tcode_op), 0)
    # opioid UCOD but no opioid T-code -> not an opioid death
    expect_true(all(f$opioid_death[ucod_op & !tcode_op] == 0))
    # opioid T-code but non-drug UCOD -> not an opioid death
    expect_true(all(f$opioid_death[!ucod_op & tcode_op] == 0))
})

test_that("ICD-10 maternal + suicide type colSums are stable", {
    proc <- flag_pipeline(flag_icd10_fixture(), year = 2019L, era = "icd10")$proc
    mat <- suppressWarnings(flag_maternal_deaths(proc, year = 2019L))
    sui <- suppressWarnings(flag_suicide_types(proc))
    expect_snapshot({
        c(maternal_death = as.integer(sum(mat$maternal_death, na.rm = TRUE)))
        vapply(c("suicide_firearm", "suicide_poison", "suicide_fall",
                          "suicide_suffocation", "suicide_other"),
                      function(cc) as.integer(sum(sui[[cc]], na.rm = TRUE)), integer(1))
    })
})
