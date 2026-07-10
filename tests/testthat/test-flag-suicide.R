# flag_suicide_* is ICD-10-only. On ICD-10 data it works (Bucket A). On ICD-9 data
# it SILENTLY returns all zeros with no warning -- the documented bug (Bucket B).
# Per the approved plan, Phase 3 adds a guard that WARNS on pre-1999 data (it does
# NOT implement ICD-9 detection). So the desired Phase-3 behavior is "warns", not
# "detects"; the skipped test asserts the warning and is un-skipped in Phase 3,
# at which point the KNOWN-BUG (silent) test below is deleted.

test_that("ICD-10: flag_suicide_deaths flags suicides", {
    proc <- flag_pipeline(flag_icd10_fixture(), year = 2019L, era = "icd10")$proc
    out <- flag_suicide_deaths(proc)
    expect_true("suicide_death" %in% names(out))
    expect_gt(sum(out$suicide_death, na.rm = TRUE), 0)
})

test_that("KNOWN BUG: ICD-9 suicide flags silently return all zeros, no warning", {
    proc <- flag_pipeline(flag_icd9_fixture(), year = 1993L, era = "icd9")$proc
    expect_no_warning(sd <- flag_suicide_deaths(proc))
    expect_equal(sum(sd$suicide_death, na.rm = TRUE), 0)
    st <- flag_suicide_types(proc)
    type_cols <- c("suicide_firearm", "suicide_poison", "suicide_fall",
                   "suicide_suffocation", "suicide_other")
    for (cc in type_cols) {
        expect_equal(sum(st[[cc]], na.rm = TRUE), 0)
    }
})

test_that("ICD-9 suicide flags warn on pre-1999 data (Phase 3 guard)", {
    skip("Bucket B: un-skip after Phase 3 adds the pre-1999 guard/warning; delete the KNOWN BUG test above")
    proc <- flag_pipeline(flag_icd9_fixture(), year = 1993L, era = "icd9")$proc
    expect_warning(flag_suicide_deaths(proc, year = 1993L), regexp = "ICD-9|1999|pre")
})
