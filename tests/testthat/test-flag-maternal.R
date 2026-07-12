# flag_maternal_deaths() is ICD-10-only but -- unlike the suicide flags -- it
# already WARNS on pre-2003 data rather than failing silently, so ICD-9 behavior
# is characterized (warns + returns 0), not treated as a silent bug. Phase 3 only
# reconciles the message wording for pre-1999; the loose regexp below tolerates that.

test_that("ICD-10 maternal deaths: ucod_only <= full, late >= regular", {
    proc <- flag_pipeline(flag_icd10_fixture(), year = 2019L, era = "icd10")$proc

    full <- suppressWarnings(flag_maternal_deaths(proc, year = 2019L))
    ucod <- suppressWarnings(flag_maternal_deaths(proc, year = 2019L, ucod_only = TRUE))
    late <- suppressWarnings(flag_maternal_deaths_late(proc, year = 2019L))

    expect_gt(sum(full$maternal_death, na.rm = TRUE), 0)
    expect_lte(sum(ucod$maternal_death, na.rm = TRUE), sum(full$maternal_death, na.rm = TRUE))
    # _late adds O96/O97 to the pattern -> >= the regular count. (Its column is
    # named maternal_death_late, not maternal_death.)
    expect_gte(sum(late$maternal_death_late, na.rm = TRUE), sum(full$maternal_death, na.rm = TRUE))
})

test_that("keep_cols = TRUE retains the auto-generated f_records_all; FALSE drops it", {
    raw <- flag_icd10_fixture()          # raw -> maternal auto-runs unite_records
    kept    <- suppressWarnings(flag_maternal_deaths(raw, year = 2019L, keep_cols = TRUE))
    dropped <- suppressWarnings(flag_maternal_deaths(raw, year = 2019L, keep_cols = FALSE))
    expect_true("f_records_all" %in% names(kept))
    expect_false("f_records_all" %in% names(dropped))
})

test_that("ICD-9 maternal deaths: returns 0 and warns (not silent)", {
    proc <- flag_pipeline(flag_icd9_fixture(), year = 1993L, era = "icd9")$proc
    expect_warning(m9 <- flag_maternal_deaths(proc, year = 1993L))
    expect_equal(sum(m9$maternal_death, na.rm = TRUE), 0)
})

test_that("flag_maternal_deaths() does not crash on an all-NA `year` column", {
    ## .extract_year() resolves an all-NA `year` column to NA; the pre-2003
    ## warning check must not choke on that NA (regression for the
    ## `if (year < 2003)` crash).
    df <- tibble::tibble(
        year = NA_real_,
        ucod = c("O95", "I250"),
        f_records_all = c("O95", "I250")
    )

    out <- expect_no_error(flag_maternal_deaths(df))
    expect_no_warning(flag_maternal_deaths(df))
    expect_equal(out$maternal_death, c(1, 0))
})

test_that("flag_maternal_deaths_late() does not crash on an all-NA `year` column", {
    df <- tibble::tibble(
        year = NA_real_,
        ucod = c("O95", "I250"),
        f_records_all = c("O95", "I250")
    )

    out <- expect_no_error(flag_maternal_deaths_late(df))
    expect_no_warning(flag_maternal_deaths_late(df))
    expect_equal(out$maternal_death_late, c(1, 0))
})
