test_that("both dictionaries have valid types and monotonic positions", {
    for (d in list(mcod_fwf_dicts, mcod_public_fwf_dicts)) {
        expect_true(all(d$type %in% c("c", "n")))
        pres <- d[is.na(d$start) == FALSE, ]
        expect_true(all(pres$start >= 1L))
        expect_true(all(pres$start <= pres$end))
    }
})

test_that("years are contiguous 1979-2024 in both tiers", {
    expect_equal(sort(unique(mcod_fwf_dicts$year)), 1979:2024)
    expect_equal(sort(unique(mcod_public_fwf_dicts$year)), 1979:2024)
})

test_that("no duplicate (name, year) in the restricted dictionary", {
    dup <- duplicated(mcod_fwf_dicts[, c("name", "year")])
    expect_false(any(dup))
})

test_that("col_types string length equals number of positions per year", {
    for (y in unique(mcod_fwf_dicts$year)) {
        rows <- mcod_fwf_dicts[mcod_fwf_dicts$year == y, ]
        ctypes <- paste(rows$type, collapse = "")
        expect_equal(nchar(ctypes), nrow(rows))
    }
})

test_that("public effective record length matches the verified profile", {
    max_end <- function(y) {
        d <- mcod_public_fwf_dicts
        max(d$end[d$year == y & !d$suppressed], na.rm = TRUE)
    }
    ## the headline public finding: 488 (2003-2012) -> 490 (2013-2019) -> 817 (2020+)
    expect_equal(max_end(2003), 488L)
    expect_equal(max_end(2012), 488L)
    expect_equal(max_end(2013), 490L)
    expect_equal(max_end(2019), 490L)
    expect_equal(max_end(2020), 817L)
    expect_equal(max_end(2024), 817L)
})

test_that("restricted record reaches 490 (2003-2019) and 817 (2020+ via declared occ/ind)", {
    max_end <- function(y) max(mcod_fwf_dicts$end[mcod_fwf_dicts$year == y])
    expect_equal(max_end(2003), 490L)
    expect_equal(max_end(2019), 490L)
    ## restricted 2020 declares occupation/industry @806-817 (populated on public
    ## 2020, read as NA on the 490-byte restricted 2020 file); wide record from 2021
    expect_equal(max_end(2020), 817L)
    expect_equal(max_end(2021), 817L)
    expect_equal(max_end(2024), 817L)
})
