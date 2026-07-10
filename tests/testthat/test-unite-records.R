# Characterization (Bucket A) for unite_records(), which collapses record_1..20
# into a single space-joined f_records_all string that every downstream flag
# regexes over. Structural properties (not hardcoded strings) so the Phase 3
# refactor of the 20 hand-written prefix_to_record lines is guarded.

test_that("ICD-10 unite_records builds f_records_all and drops the record columns", {
    out <- suppressWarnings(unite_records(flag_icd10_fixture(), year = 2019L))
    expect_true("f_records_all" %in% names(out))
    expect_type(out$f_records_all, "character")
    expect_false(any(grepl("^record_", names(out))))   # source columns consumed
    expect_false(any(grepl(" NA", out$f_records_all)))  # trailing NA tokens stripped
    # a row whose contributory causes include T40.1 keeps it in the united string
    row <- out[grepl("T401", out$f_records_all), ][1, ]
    expect_true(grepl("T401", row$f_records_all))
})

test_that("ICD-9 unite_records (after clean_icd9_data) drops record_ and rnifla_", {
    cleaned <- clean_icd9_data(flag_icd9_fixture())
    out <- suppressWarnings(unite_records(cleaned, year = 1993L))
    expect_true("f_records_all" %in% names(out))
    expect_false(any(grepl("^record_", names(out))))
    expect_false(any(grepl("^rnifla", names(out))))
    expect_false(any(grepl(" NA", out$f_records_all)))
})
