# Characterization (Bucket A) for the ICD-9 (1979-1998) flag pipeline, on the real
# 1993 public fixture (raw -> clean_icd9_data -> unite_records -> flag_*). The
# colSums snapshot locks aggregate behavior. Explicit zero-assertions lock the
# CORRECT ICD-9 domain behavior: ISW7 defines no ICD-9 codes for opium, natural,
# or synthetic opioids, and ICD-9 cannot distinguish multiple opioid types -- so
# those flags MUST stay 0. (This is not the suicide/maternal bug; see those tests.)

test_that("ICD-9 flag pipeline colSums are stable", {
    r <- flag_pipeline(flag_icd9_fixture(), year = 1993L, era = "icd9")
    expect_snapshot(flag_sums(r$flagged))
})

test_that("ICD-9 has no opium/natural/synthetic/multi-opioid deaths (correct domain behavior)", {
    r <- flag_pipeline(flag_icd9_fixture(), year = 1993L, era = "icd9")
    f <- r$flagged
    expect_equal(sum(f$opium_present, na.rm = TRUE), 0)
    expect_equal(sum(f$other_natural_present, na.rm = TRUE), 0)
    expect_equal(sum(f$other_synth_present, na.rm = TRUE), 0)
    expect_equal(sum(f$multi_opioids, na.rm = TRUE), 0)
})

test_that("ICD-9 detects heroin and methadone via E-codes", {
    r <- flag_pipeline(flag_icd9_fixture(), year = 1993L, era = "icd9")
    f <- r$flagged
    expect_gt(sum(f$heroin_present, na.rm = TRUE), 0)
    expect_gt(sum(f$methadone_present, na.rm = TRUE), 0)
    expect_true(all(f$opioid_death[f$heroin_present == 1] == 1))
})
