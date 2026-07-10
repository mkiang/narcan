# Characterization (Bucket A) for the human-readable labelers, on the real ICD-10
# fixture. Snapshots lock the label distributions; the value sets are asserted so
# a refactor cannot silently introduce an unexpected label.

test_that("label_od_intent() adds od_intent with the expected label set", {
    flagged <- flag_pipeline(flag_icd10_fixture(), year = 2019L, era = "icd10")$flagged
    out <- label_od_intent(flagged)
    expect_true("od_intent" %in% names(out))
    expect_true(all(out$od_intent %in%
        c("unintended", "suicide", "homicide", "undetermined", "not_overdose")))
    expect_snapshot(sort(table(out$od_intent)))
})

test_that("label_suicide_type() adds suicide_type with the expected label set", {
    proc <- flag_pipeline(flag_icd10_fixture(), year = 2019L, era = "icd10")$proc
    typed <- suppressWarnings(flag_suicide_types(proc))
    out <- label_suicide_type(typed)
    expect_true("suicide_type" %in% names(out))
    expect_true(all(out$suicide_type %in%
        c("suicide_firearm", "suicide_poison", "suicide_fall",
            "suicide_suffocation", "suicide_other", "not_suicide")))
    expect_snapshot(sort(table(out$suicide_type)))
})
