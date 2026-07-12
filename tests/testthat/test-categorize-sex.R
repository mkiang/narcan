# Regression tests for two 0.5.1 categorize_sex() fixes:
# 1. a `year` vector whose length is neither 1 nor length(sex_column) was
#    silently recycled (misaligned era assignment); it must now hard-error.
# 2. empty `sex_column` input crashed with a cryptic "missing value where
#    TRUE/FALSE needed" (modern[1] was NA when n == 0); it must now return
#    character(0) cleanly.

test_that("a misaligned year vector errors instead of silently recycling (0.5.1)", {
    expect_error(
        categorize_sex(c(1, 2, 1, 2), year = c(2000, 2010)),
        "aligned"
    )
    expect_error(
        categorize_female(c(1, 2, 1, 2), year = c(2000, 2010)),
        "aligned"
    )
})

test_that("an aligned year vector still maps correctly (0.5.1)", {
    expect_equal(
        categorize_female(c(1, 2, 1, 2), year = c(2000, 1995, 1980, 2001)),
        c(0L, 1L, 0L, 1L)
    )
})

test_that("empty sex_column input returns character(0) cleanly (0.5.1)", {
    expect_identical(categorize_sex(character(0), year = NULL), character(0))
    expect_identical(categorize_sex(numeric(0), year = NULL), character(0))
    expect_identical(categorize_sex(character(0)), character(0))
    expect_identical(categorize_sex(numeric(0)), character(0))
})

test_that("empty sex_column input with a non-NULL year already worked and still does (0.5.1)", {
    expect_identical(categorize_sex(character(0), year = 2019), character(0))
    expect_identical(categorize_sex(numeric(0), year = 2000), character(0))
})
