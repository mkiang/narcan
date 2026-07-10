# flag_suicide_* is ICD-10-only. On ICD-10 data it flags (Bucket A). On ICD-9 data
# it now WARNS (Phase 3 guard) instead of silently returning zeros, but still
# returns 0 -- ICD-9 suicide detection is a future work item.

test_that("ICD-10: flag_suicide_deaths flags suicides (no warning)", {
    proc <- flag_pipeline(flag_icd10_fixture(), year = 2019L, era = "icd10")$proc
    expect_no_warning(out <- flag_suicide_deaths(proc))
    expect_true("suicide_death" %in% names(out))
    expect_gt(sum(out$suicide_death, na.rm = TRUE), 0)
})

test_that("ICD-9: flag_suicide_deaths warns and returns all zeros", {
    proc <- flag_pipeline(flag_icd9_fixture(), year = 1993L, era = "icd9")$proc
    expect_warning(sd <- flag_suicide_deaths(proc), regexp = "ICD-10|1999")
    expect_equal(sum(sd$suicide_death, na.rm = TRUE), 0)
})

test_that("ICD-9: flag_suicide_types warns once and returns all zeros", {
    proc <- flag_pipeline(flag_icd9_fixture(), year = 1993L, era = "icd9")$proc
    expect_warning(st <- flag_suicide_types(proc), regexp = "ICD-10|1999")
    for (cc in c("suicide_firearm", "suicide_poison", "suicide_fall",
                 "suicide_suffocation", "suicide_other")) {
        expect_equal(sum(st[[cc]], na.rm = TRUE), 0)
    }
})

test_that("ICD-10: flag_suicide_types does not warn", {
    proc <- flag_pipeline(flag_icd10_fixture(), year = 2019L, era = "icd10")$proc
    expect_no_warning(flag_suicide_types(proc))
})
