# Direct unit tests for the exported ICD-9 munging leaf helpers, previously
# exercised only indirectly through clean_icd9_data()/unite_records().

test_that("pad_3char_codes() pads only 3-char codes with a trailing 0", {
    expect_equal(pad_3char_codes(c("400", "4043", "304", "5062")),
                 c("4000", "4043", "3040", "5062"))
})

test_that("prefix_e_to_ucod() prefixes E to codes in [8000, 9999] only", {
    expect_equal(prefix_e_to_ucod(c("7951", "8001", "9992", "6000", "4000")),
                 c("7951", "E8001", "E9992", "6000", "4000"))
})

test_that("prefix_to_record() applies E/N by the nature-of-injury flag", {
    rec <- c("7500", "8000", "8001", "9999", "10000")
    nif <- c(0, 1, 0, 1, 0)
    expect_equal(prefix_to_record(rec, nif),
                 c("7500", "N8000", "E8001", "N9999", "10000"))
})

test_that("trim_5char_record() keeps the first 4 characters", {
    expect_equal(trim_5char_record(c("400 1", "40000", "400", "400 ")),
                 c("400 ", "4000", "400", "400 "))
})

test_that("trim_trailing_whitespace() strips a trailing space on 3-char codes", {
    expect_equal(trim_trailing_whitespace(c("400 ", "402", "4032")),
                 c("400", "402", "4032"))
})

test_that("rename_ni_flag() renames rniflag_ to rnifla_", {
    df <- data.frame(rniflag_1 = c(0, 1), record_1 = c("E850", "9650"))
    out <- rename_ni_flag(df)
    expect_true("rnifla_1" %in% names(out))
    expect_false("rniflag_1" %in% names(out))
})
