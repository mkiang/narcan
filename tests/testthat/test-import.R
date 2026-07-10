test_that("restricted import round-trips values and column classes", {
    dict <- mini_restricted_dict()
    f <- write_fixture()

    df <- .import_mcod_data(f, 2050L, tier = "restricted",
                            dict = dict, restricted_dict = dict)

    ## importer guarantees a canonical `year` column (appended when the dict has
    ## no year/datayear field of its own)
    expect_equal(names(df), c("cty", "st", "sex", "age", "ucod", "year"))
    expect_equal(df$year, c(2050, 2050))
    expect_type(df$cty, "character")
    expect_type(df$age, "double")     # readr "n" -> double
    expect_type(df$ucod, "character")
    expect_equal(df$cty, c("06075", "36061"))
    expect_equal(df$st, c("06", "36"))
    expect_equal(df$sex, c("M", "F"))
    expect_equal(df$age, c(7, 88))
    expect_equal(df$ucod, c("C509", "X44"))  # trailing space -> NA-trimmed to "X44"
})

test_that("public import keeps suppressed columns as typed all-NA with parity", {
    rdict <- mini_restricted_dict()
    pdict <- mini_public_dict()
    f <- write_fixture()

    pub <- .import_mcod_data(f, 2050L, tier = "public",
                             dict = pdict, restricted_dict = rdict)

    ## same columns, same order as the restricted layout, plus the canonical year
    expect_equal(names(pub), c(mini_restricted_dict()$name, "year"))
    expect_equal(pub$year, c(2050, 2050))
    ## suppressed geography is all-NA of the right type
    expect_true(all(is.na(pub$cty)))
    expect_true(all(is.na(pub$st)))
    expect_type(pub$cty, "character")
    ## non-suppressed columns still parse
    expect_equal(pub$sex, c("M", "F"))
    expect_equal(pub$age, c(7, 88))
})

test_that("import errors clearly on an unknown year", {
    dict <- mini_restricted_dict()
    f <- write_fixture()
    expect_error(
        .import_mcod_data(f, 1900L, tier = "restricted",
                          dict = dict, restricted_dict = dict),
        "no restricted dictionary for year 1900"
    )
})
