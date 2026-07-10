# Characterization (Bucket A) for clean_icd9_data() and its helpers, on the real
# 1993 fixture. clean_icd9_data renames rniflag_ -> rnifla_, pads/prefixes the
# UCOD, and trims/pads the record columns. The snapshot locks the exact cleaned
# UCOD values; structural asserts lock the rename.

test_that("clean_icd9_data() renames rniflag_ -> rnifla_ and keeps ucod character", {
    cleaned <- clean_icd9_data(flag_icd9_fixture())
    expect_false(any(grepl("^rniflag_", names(cleaned))))   # old name gone
    expect_true(any(grepl("^rnifla_", names(cleaned))))     # new name present
    expect_type(cleaned$ucod, "character")
    expect_equal(nrow(cleaned), nrow(flag_icd9_fixture()))
})

test_that("clean_icd9_data() cleaned UCOD values are stable", {
    cleaned <- clean_icd9_data(flag_icd9_fixture())
    expect_snapshot(head(cleaned$ucod, 12))
})
