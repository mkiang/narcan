# Branch/parameter coverage the plan's review called out for the opioid subtype
# family. These lock behavior that the era-level snapshots don't reach.

test_that("keep_cols = TRUE retains the auto-generated f_records_all; FALSE drops it", {
    # Drive the branch that actually differs: raw input (no f_records_all yet) so
    # flag_opioid_deaths auto-generates it. keep_cols=TRUE keeps it; FALSE drops it
    # (it is not among the original columns). ncol alone would be tautological here.
    raw <- flag_icd10_fixture()
    expect_false("f_records_all" %in% names(raw))
    kept    <- suppressWarnings(flag_opioid_deaths(raw, year = 2019L, keep_cols = TRUE))
    dropped <- suppressWarnings(flag_opioid_deaths(raw, year = 2019L, keep_cols = FALSE))
    expect_true("f_records_all" %in% names(kept))
    expect_false("f_records_all" %in% names(dropped))
    expect_true("opioid_death" %in% names(dropped))
})

test_that("missing_val threads through when a subtype has no ICD-9 codes", {
    # On ICD-9 data, opium has no code -> flag_opium_present sets the column to
    # missing_val (default 0). A custom value must appear verbatim.
    proc <- flag_pipeline(flag_icd9_fixture(), year = 1993L, era = "icd9")$proc
    out <- suppressWarnings(flag_opium_present(proc, year = 1993L, missing_val = 99))
    expect_true(all(out$opium_present == 99))
})

test_that("DAG landmine: a non-heroin subtype flag errors without opioid_death", {
    # flag_heroin_present self-heals, but the other subtype flags read opioid_death
    # directly. Calling one before flag_opioid_deaths() errors -- locked as current
    # behavior so a refactor is a conscious choice, not an accident.
    proc <- flag_pipeline(flag_icd10_fixture(), year = 2019L, era = "icd10")$proc
    expect_false("opioid_death" %in% names(proc))
    expect_error(suppressWarnings(flag_methadone_present(proc, year = 2019L)),
                 regexp = "opioid_death")
})
