# Golden regression for the ICD-9 auto-clean fix (0.5.1). unite_records() now runs
# the idempotent clean_icd9_data() internally for the ICD-9 era, so the documented
# flag_* pipeline is CORRECT on raw pre-1999 data without a manual
# clean_icd9_data() step. Before the fix, a raw ICD-9 frame silently mis-flagged
# every drug/opioid death (mis-formatted E-codes and nature-of-injury codes miss
# the ICD-9 regex) or errored on the rniflag_-named nature-of-injury columns
# (1991-1995 files).

test_that("unite_records auto-cleans a raw ICD-9 frame (no crash)", {
    raw <- flag_icd9_fixture()                     # real raw (pre-clean) 1993 sample
    expect_no_error(suppressWarnings(unite_records(raw, 1993L)))
})

test_that("flag_* on raw ICD-9 == the explicit-clean path, and is not silently zero", {
    raw <- flag_icd9_fixture()
    raw_path <- suppressWarnings(flag_drug_deaths(unite_records(raw, 1993L), 1993L))
    cln_path <- suppressWarnings(
        flag_drug_deaths(unite_records(clean_icd9_data(raw), 1993L), 1993L))
    expect_identical(raw_path$drug_death, cln_path$drug_death)   # idempotent -> same
    expect_gt(sum(raw_path$drug_death), 0)                       # not the old all-zero
})
